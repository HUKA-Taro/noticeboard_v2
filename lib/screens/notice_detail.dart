import 'dart:convert';
import 'dart:async';
import 'shortlist_counts.dart';
import 'shortlist_profiles.dart';
import 'package:noticeboard/bloc/list_notices_bloc.dart';
import 'package:noticeboard/bloc/notice_detail_bloc.dart';
import 'package:noticeboard/enum/current_widget_enum.dart';
import 'package:noticeboard/enum/notice_content_enum.dart';
import 'package:noticeboard/routes/routing_constants.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import '../global/global_constants.dart';
import '../models/notice_intro.dart';
import 'package:flutter/material.dart';
import '../bloc/notice_content_bloc.dart';
import '../global/global_functions.dart';
import '../styles/notice_detail_consts.dart';

// ignore: must_be_immutable
class NoticeDetail extends StatefulWidget {
  final NoticeIntro? noticeIntro;
  List<NoticeIntro?>? listOfNotices;
  ListNoticesBloc listNoticesBloc;
  NoticeDetail(
      {required this.noticeIntro,
      required this.listOfNotices,
      required this.listNoticesBloc});

  @override
  _NoticeDetailState createState() => _NoticeDetailState();
}

class _NoticeDetailState extends State<NoticeDetail> {
  NoticeContentBloc _noticeContentBloc = NoticeContentBloc();
  PlatformWebViewController _webViewController = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams());
  NoticeDetailBloc _noticeDetailBloc = NoticeDetailBloc();
  bool pdfAlreadyOpened = false;
  bool snackBarShown = false;
  late StreamSubscription _streamSubscription;
  int currentIndex = 0;
  String? _noticeHtml;
  ShortlistProfiles? _profiles;
  bool _showProfiles = false;
  String? _renderedHtml;
  Timer? _profileRefresh;

  bool get _isShortlist {
    final title = widget.noticeIntro?.title?.toLowerCase() ?? '';
    final content = _noticeHtml?.toLowerCase() ?? '';
    return title.contains('shortlist') || content.contains('shortlist');
  }

  ShortlistProfiles _loadProfiles() {
    final existing = _profiles;
    if (existing != null) return existing;
    final profiles = ShortlistProfiles(_noticeHtml!);
    _profiles = profiles;
    profiles.addListener(() {
      if (!_showProfiles || _profileRefresh?.isActive == true) return;
      _profileRefresh = Timer(const Duration(seconds: 1), () {
        if (mounted && _profiles == profiles && _showProfiles) {
          setState(() {});
        }
      });
    });
    if (profiles.hasLinks) unawaited(profiles.loadAcademicDetails());
    return profiles;
  }

  void _toggleProfiles() {
    if (_showProfiles) {
      setState(() => _showProfiles = false);
      return;
    }
    if (!_loadProfiles().hasLinks) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No clearly labelled enrollment numbers found.'),
      ));
      return;
    }
    setState(() => _showProfiles = true);
  }

  void _showCounts() {
    final profiles = _loadProfiles();
    showDialog<void>(
      context: context,
      builder: (_) => ShortlistCounts(profiles: profiles),
    );
  }

  @override
  void initState() {
    _noticeContentBloc.context = context;
    _noticeContentBloc.noticeIntro = widget.noticeIntro;
    _noticeContentBloc.starred = widget.noticeIntro!.starred;
    _noticeContentBloc.eventSink.add(NoticeContentEvents.fetchContent);
    _streamSubscription = _noticeDetailBloc.eventStream.listen((event) {
      if (event == CurrentWidget.noticeDetail) {
        _noticeContentBloc.eventSink.add(NoticeContentEvents.fetchContent);
        _webViewController.reload();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _profileRefresh?.cancel();
    _profiles?.dispose();
    _noticeContentBloc.disposeStreams();
    // Canceling the stream subscription so it does not leaves a dangling listener to the stream preventing race condition
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery.of(context).size.width;
    double _height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        leadingWidth: 30.0,
        leading: IconButton(
          icon: screenPopIcon(Colors.white),
          onPressed: () {
            if (previousRoute == launchingRoute) {
              navigatorKey.currentState!
                  .pushReplacementNamed(bottomNavigationRoute);
            } else {
              navigatorKey.currentState!.pop();
            }
          },
        ),
        backgroundColor: globalBlueColor,
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (action) {
              if (_noticeHtml == null || !_isShortlist) return;
              if (action == 'counts') {
                _showCounts();
              } else {
                _toggleProfiles();
              }
            },
            itemBuilder: (_) => [
              if (_noticeHtml != null && _isShortlist)
                const PopupMenuItem(
                  value: 'counts',
                  child: Text('Show counts'),
                ),
              PopupMenuItem(
                value: 'profiles',
                enabled: _isShortlist && _noticeHtml != null,
                child: Text(_showProfiles
                    ? 'Hide student profiles'
                    : 'Show student profiles'),
              ),
            ],
          ),
        ],
        title: Text(
          widget.noticeIntro!.department!,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) {
            return;
          }
          if (previousRoute == launchingRoute) {
            navigatorKey.currentState!
                .pushReplacementNamed(bottomNavigationRoute);
          } else {
            navigatorKey.currentState!.pop();
          }
        },
        child: Container(
          width: _width,
          height: _height * 0.88,
          child: Column(
            children: [
              buildNoticeIntro(_width),
              buildNoticeContent(_width),
            ],
          ),
        ),
      ),
    );
  }

  Expanded buildNoticeContent(double width) {
    return Expanded(
      child: Container(
        color: Colors.white,
        width: width,
        child: Center(
          child: StreamBuilder(
            stream: _noticeContentBloc.contentStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return buildContent(snapshot);
              } else if (snapshot.hasError) {
                return buildErrorWidget(snapshot);
              }
              return buildLoadingWidget();
            },
          ),
        ),
      ),
    );
  }

  String wrapHtmlHeaders(String originalHtml) {
    return """
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=5.0, user-scalable=yes">
          <style>
            body {
              font-family: sans-serif;
              font-size: 0.65em;
            }
            img {
              height: auto;
              max-width: 100%;
            }
          </style>
        </head>
        <body>
          $originalHtml
        </body>
      </html>
    """;
  }

  Container buildContent(AsyncSnapshot snapshot) {
    final source = snapshot.data.content as String? ?? '';
    if (_noticeHtml != source) {
      _noticeHtml = source;
      _profileRefresh?.cancel();
      _profiles?.dispose();
      _profiles = null;
      _renderedHtml = null;
      _showProfiles = false;
    }
    final content = _showProfiles ? _profiles?.markup ?? source : source;
    if (_renderedHtml == content) {
      return Container(child: webviewFromCreationParams(_webViewController));
    }
    final modifiedHtml = wrapHtmlHeaders(content);
    final firstLoad = _renderedHtml == null;
    _renderedHtml = content;
    if (!firstLoad && _showProfiles) {
      // Replace the body in place so a progressing lookup preserves the scroll.
      // If the initial document is still loading, reload the full notice.
      unawaited(_updateWebView(content, modifiedHtml));
      return Container(child: webviewFromCreationParams(_webViewController));
    }
    final delegate = PlatformNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    );
    delegate.setOnNavigationRequest((navigation) async {
      final url = navigation.url;
      if (url.endsWith(".pdf") && !pdfAlreadyOpened) {
        pdfAlreadyOpened = true;
        if (await canLaunchUrlString(url)) {
          final newUrl = "https://docs.google.com/gview?embedded=true&url=$url";
          await launchUrlString(newUrl);
        }
        return NavigationDecision.prevent;
      } else {
        if (await canLaunchUrlString(url)) {
          await launchUrlString(
            url,
            mode: LaunchMode.externalApplication,
          );
          return NavigationDecision.prevent;
        }
      }
      return NavigationDecision.navigate;
    });
    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setPlatformNavigationDelegate(delegate)
      ..enableZoom(true)
      ..loadHtmlString(modifiedHtml);

    return Container(child: webviewFromCreationParams(_webViewController));
  }

  Future<void> _updateWebView(String content, String fullHtml) async {
    try {
      await _webViewController.runJavaScript(
        'document.body.innerHTML = ${jsonEncode(content)};',
      );
    } catch (_) {
      if (mounted && _renderedHtml == content) {
        await _webViewController.loadHtmlString(fullHtml);
      }
    }
  }

  Container buildNoticeIntro(double _width) {
    return Container(
      color: globalLightBlueColor,
      width: _width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.noticeIntro!.title!,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              ],
            ),
            sizedBox(5.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.noticeIntro!.dateCreated!),
                Row(
                  children: [
                    StreamBuilder<bool?>(
                      stream: _noticeContentBloc.starStream,
                      initialData: widget.noticeIntro!.starred,
                      builder: (context, snapshot) {
                        return GestureDetector(
                            onTap: () {
                              widget.listNoticesBloc.toggleBookMarkSink
                                  .add(widget.noticeIntro!);
                              _noticeContentBloc.eventSink
                                  .add(NoticeContentEvents.toggleStar);
                            },
                            child: bookMarkIconDecider(snapshot.data!));
                      },
                    ),
                    SizedBox(
                      width: 10.0,
                    ),
                    GestureDetector(
                      onTap: () {
                        _noticeContentBloc.eventSink
                            .add(NoticeContentEvents.shareNotice);
                      },
                      child: shareIcon,
                    )
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
