import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

import '../services/auth/auth_service.dart';

final _enrollment = RegExp(r'^\d{8}$');
final _label = RegExp(
  r'\b(?:enrol{1,2}ment|roll)\s*(?:no\.?|number|#)?\s*[:#-]?\s*(\d{8})\b',
  caseSensitive: false,
);

dom.Element _link(String id) => dom.Element.tag('a')
  ..attributes['href'] = 'https://channeli.in/student_profile/$id/'
  ..text = id;

class ShortlistProfiles {
  ShortlistProfiles(String source) : _body = html.parse(source).body! {
    for (final table in _body.querySelectorAll('table')) {
      int? enrollmentColumn;
      for (final row in table.querySelectorAll('tr')) {
        final cells = row.children
            .where((cell) => cell.localName == 'td' || cell.localName == 'th')
            .toList();
        final label = cells.indexWhere((cell) => RegExp(
              r'^\s*(?:enrol{1,2}ment|roll)(?:\s*(?:no\.?|number|#))?\s*$',
              caseSensitive: false,
            ).hasMatch(cell.text));
        if (label >= 0) {
          enrollmentColumn = label;
          continue;
        }
        if (enrollmentColumn == null || enrollmentColumn >= cells.length)
          continue;
        final cell = cells[enrollmentColumn];
        final id = cell.text.trim();
        if (!_enrollment.hasMatch(id) || cell.querySelector('a') != null)
          continue;
        final link = _link(id);
        cell.nodes
          ..clear()
          ..add(link);
        _entries.putIfAbsent(id, () => []).add(link);
      }
    }
    _linkLabelledNumbers(_body);
  }

  final dom.Element _body;
  final Map<String, List<dom.Element>> _entries = {};
  bool get hasLinks => _entries.isNotEmpty;
  String get markup => _body.innerHtml;

  void _linkLabelledNumbers(dom.Element element) {
    if (const {'a', 'script', 'style'}.contains(element.localName)) return;
    for (final node in element.nodes.toList()) {
      if (node is dom.Element) {
        _linkLabelledNumbers(node);
      } else if (node is dom.Text) {
        final raw = node.text;
        final matches = _label.allMatches(raw).toList();
        if (matches.isEmpty) continue;
        var start = 0;
        for (final match in matches) {
          final id = match.group(1)!;
          final offset = match.end - id.length;
          element.insertBefore(dom.Text(raw.substring(start, offset)), node);
          final link = _link(id);
          element.insertBefore(link, node);
          _entries.putIfAbsent(id, () => []).add(link);
          start = match.end;
        }
        element.insertBefore(dom.Text(raw.substring(start)), node);
        node.remove();
      }
    }
  }

  Future<void> loadAcademicDetails({required bool Function() active}) async {
    final access = (await AuthService().fetchAccessToken()).accessToken;
    if (access == null || access.isEmpty || !active()) return;
    final client = http.Client();
    try {
      final ids = _entries.keys.toList();
      var authorized = true;
      for (var offset = 0;
          offset < ids.length && active() && authorized;
          offset += 4) {
        await Future.wait(ids.skip(offset).take(4).map((id) async {
          try {
            final uri =
                Uri.https('channeli.in', '/api/people_search/student_search/', {
              'query': id,
              'page': '1',
              'categoryOptions[]': 'enrollment',
            });
            final request = http.Request('GET', uri)..followRedirects = false;
            request.headers['Authorization'] = 'Bearer $access';
            final response = await client
                .send(request)
                .then(http.Response.fromStream)
                .timeout(const Duration(seconds: 6));
            if (response.statusCode == 401 || response.statusCode == 403) {
              authorized = false;
            }
            if (response.statusCode != 200 || !active()) return;
            final result = jsonDecode(utf8.decode(response.bodyBytes));
            final rows = result is Map ? result['results'] : result;
            if (rows is! List) return;
            for (final row in rows.whereType<Map>()) {
              if (row['enrolmentNumber']?.toString() != id) continue;
              final parts = <String>[
                if (row['branchName'] case final String branch
                    when branch.isNotEmpty)
                  branch,
                if (row['currentYear'] != null) 'Year ${row['currentYear']}',
              ];
              if (parts.isEmpty) break;
              for (final link in _entries[id]!) {
                final parent = link.parent!;
                final line = dom.Element.tag('small')..text = parts.join(' · ');
                final index = parent.nodes.indexOf(link) + 1;
                final next =
                    index < parent.nodes.length ? parent.nodes[index] : null;
                parent.insertBefore(dom.Element.tag('br'), next);
                parent.insertBefore(line, next);
              }
              break;
            }
          } catch (_) {
            // Profile links still work through the browser session.
          }
        }));
      }
    } finally {
      client.close();
    }
  }
}
