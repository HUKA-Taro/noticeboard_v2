import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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

final _enrollmentHeader = RegExp(
  r'^(?:enrol{1,2}ment|roll)(?:\s*(?:no\.?|number|#))?$',
  caseSensitive: false,
);
final _roomHeader = RegExp(
  r'^(?:(?:test|exam|interview)\s+)?room(?:\s*(?:no\.?|number|#))?$',
  caseSensitive: false,
);
final _roomLabel = RegExp(
  r'^room(?:\s*(?:no\.?|number|#))?(?:\s*[:#-]\s*|\s+)([a-z0-9]+(?:[- ][a-z0-9]+){0,3})$',
  caseSensitive: false,
);

String _cellText(dom.Element cell) =>
    cell.text.replaceAll(RegExp(r'\s+'), ' ').trim();

dom.Element? _parentTable(dom.Element element) {
  for (var parent = element.parent; parent != null; parent = parent.parent) {
    if (parent.localName == 'table') return parent;
  }
  return null;
}

class ShortlistProfiles extends ChangeNotifier {
  ShortlistProfiles(String source) : _body = html.parse(source).body! {
    String? sectionRoom;
    for (final element in _body.querySelectorAll('h1,h2,h3,h4,h5,h6,p,table')) {
      if (element.localName != 'table') {
        if (_parentTable(element) == null) {
          sectionRoom = _roomLabel.firstMatch(_cellText(element))?.group(1) ??
              (element.localName == 'p' ? sectionRoom : null);
        }
        continue;
      }
      final caption = element.querySelector('caption');
      var room = caption == null
          ? sectionRoom
          : _roomLabel.firstMatch(_cellText(caption))?.group(1) ?? sectionRoom;
      var enrollmentColumn = -1;
      var roomColumn = -1;
      final carried = <int, (dom.Element, int)>{};
      for (final row in element.querySelectorAll('tr')) {
        if (_parentTable(row) != element) continue;
        final cells = <int, dom.Element>{};
        for (final column in carried.keys.toList()) {
          final (cell, remaining) = carried[column]!;
          cells[column] = cell;
          if (remaining == 1) {
            carried.remove(column);
          } else {
            carried[column] = (cell, remaining - 1);
          }
        }
        var column = 0;
        for (final cell in row.children.where(
            (cell) => cell.localName == 'td' || cell.localName == 'th')) {
          final width = (int.tryParse(cell.attributes['colspan'] ?? '') ?? 1)
              .clamp(1, 100);
          final height = (int.tryParse(cell.attributes['rowspan'] ?? '') ?? 1)
              .clamp(1, 10000);
          for (var i = 0; i < width; i++) {
            while (cells.containsKey(column)) {
              column++;
            }
            cells[column] = cell;
            if (height > 1) carried[column] = (cell, height - 1);
            column++;
          }
        }
        final roomHeading = row.children.length == 1
            ? _roomLabel.firstMatch(_cellText(row.children.single))?.group(1)
            : null;
        if (roomHeading != null) {
          room = roomHeading;
          continue;
        }
        final headers = cells.entries.where(
            (entry) => _enrollmentHeader.hasMatch(_cellText(entry.value)));
        if (headers.isNotEmpty) {
          enrollmentColumn = headers.first.key;
          roomColumn = -1;
          for (final entry in cells.entries) {
            if (_roomHeader.hasMatch(_cellText(entry.value))) {
              roomColumn = entry.key;
              break;
            }
          }
          continue;
        }
        final cell = cells[enrollmentColumn];
        if (cell == null) continue;
        final id = _cellText(cell);
        if (!_enrollment.hasMatch(id)) continue;
        final roomCell = cells[roomColumn];
        final assigned = roomCell == null ? room : _cellText(roomCell);
        if (assigned != null && assigned.isNotEmpty && assigned != '-') {
          _rooms.putIfAbsent(id, () => {}).add(assigned.toUpperCase());
        }
        final existing = cell.querySelector('a');
        if (existing != null) {
          final links = _entries.putIfAbsent(id, () => []);
          if (!links.contains(existing)) links.add(existing);
          continue;
        }
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
  final _entries = <String, List<dom.Element>>{};
  final _rooms = <String, Set<String>>{};
  final _branches = <String, String>{};
  final _finished = <String>{};
  bool _disposed = false;
  bool signInRequired = false;
  bool get hasLinks => _entries.isNotEmpty;
  int get total => _entries.length;
  int get pending => total - _finished.length;
  int get unavailable => _finished.length - _branches.length;
  int get unknownRooms =>
      _entries.keys.where((id) => !_rooms.containsKey(id)).length;
  String get markup => _body.innerHtml;

  Map<String, int> _counts(Iterable<String> groups) {
    final counts = <String, int>{};
    for (final group in groups) {
      counts.update(group, (value) => value + 1, ifAbsent: () => 1);
    }
    return Map.fromEntries(
        counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  Map<String, int> get roomCounts =>
      _counts(_entries.keys.expand((id) => _rooms[id] ?? const <String>{}));
  Map<String, int> get branchCounts => _counts(_branches.values);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

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

  Future<void> loadAcademicDetails() async {
    final auth = AuthService();
    final client = http.Client();
    Future<String?>? refresh;
    var access = '';
    try {
      access = (await auth.fetchAccessToken()).accessToken ?? '';
      if (access.isEmpty) {
        signInRequired = true;
        return;
      }
      final ids = _entries.keys.toList();
      for (var offset = 0; offset < ids.length && !_disposed; offset += 4) {
        final batch = ids.skip(offset).take(4);
        await Future.wait(batch.map((id) async {
          final uri =
              Uri.https('channeli.in', '/api/people_search/student_search/', {
            'query': id,
            'page': '1',
            'categoryOptions[]': 'enrollment',
          });
          for (var attempt = 0; attempt < 3 && !_disposed; attempt++) {
            try {
              final token = access;
              final request = http.Request('GET', uri)..followRedirects = false;
              request.headers['Authorization'] = 'Bearer $token';
              final response = await client
                  .send(request)
                  .then(http.Response.fromStream)
                  .timeout(const Duration(seconds: 10));
              if (_disposed) return;
              if (response.statusCode == 401) {
                if (token == access) {
                  final updated = await (refresh ??= () async {
                    try {
                      final renewed = await auth
                          .fetchAccessTokenFromRefresh()
                          .timeout(const Duration(seconds: 10));
                      final value = renewed.accessToken;
                      if (value == null || value.isEmpty || value == token)
                        return null;
                      await auth.storeAccessToken(renewed);
                      return value;
                    } catch (_) {
                      return null;
                    }
                  }());
                  if (updated == null || updated == token) {
                    signInRequired = true;
                    return;
                  }
                  access = updated;
                }
                continue;
              }
              if (response.statusCode == 200) {
                _addAcademicDetails(id, response.bodyBytes);
                return;
              }
              if (response.statusCode != 429 && response.statusCode < 500)
                return;
              final retry = int.tryParse(response.headers['retry-after'] ?? '');
              if (retry != null && retry > 30) return;
              if (attempt < 2) {
                await Future<void>.delayed(
                    Duration(seconds: retry ?? (2 << attempt)));
              }
            } catch (_) {
              if (attempt < 2) {
                await Future<void>.delayed(Duration(seconds: 2 << attempt));
              }
            }
          }
        }));
        if (_disposed) return;
        _finished.addAll(batch);
        if (signInRequired) break;
        notifyListeners();
        if (offset + 4 < ids.length) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
      }
    } catch (_) {
      // Keep profile links and room counts usable if lookup cannot start.
    } finally {
      client.close();
      if (!_disposed) {
        _finished.addAll(_entries.keys);
        notifyListeners();
      }
    }
  }

  void _addAcademicDetails(String id, List<int> body) {
    final result = jsonDecode(utf8.decode(body));
    final rows = result is Map ? result['results'] : result;
    if (rows is! List) return;
    for (final row in rows.whereType<Map>()) {
      if ((row['enrolmentNumber'] ?? row['enrollmentNumber'])?.toString() !=
          id) {
        continue;
      }
      final branch = row['branchName'];
      if (branch is String && branch.trim().isNotEmpty) {
        _branches[id] = branch.trim();
      }
      final parts = [
        _branches[id] ?? 'Branch unavailable',
        if (row['currentYear'] != null) "Year " + row['currentYear'].toString(),
      ];
      for (final link in _entries[id]!) {
        final parent = link.parent!;
        final line = dom.Element.tag('small')..text = parts.join(' \u00b7 ');
        final index = parent.nodes.indexOf(link) + 1;
        final next = index < parent.nodes.length ? parent.nodes[index] : null;
        parent.insertBefore(dom.Element.tag('br'), next);
        parent.insertBefore(line, next);
      }
      return;
    }
  }
}
