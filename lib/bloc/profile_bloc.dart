import 'dart:async';
import 'package:noticeboard/enum/dynamic_fetch_enum.dart';
import 'package:noticeboard/models/notice_intro.dart';
import 'package:noticeboard/repository/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:noticeboard/routes/routing_constants.dart';
import 'package:noticeboard/services/endpoints/urls.dart';
import '../enum/profile_enum.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global/global_constants.dart';

class ProfileBloc {
  late BuildContext context;

  final _eventController = StreamController<ProfileEvents>();
  StreamSink<ProfileEvents> get eventSink => _eventController.sink;
  Stream<ProfileEvents> get _eventStream => _eventController.stream;

  ProfileRepository _profileRepository = ProfileRepository();

  ProfileBloc() {
    _eventStream.listen((event) {
      if (event == ProfileEvents.logoutEvent) {
        _profileRepository.logout(context);
      } else if (event == ProfileEvents.bookmarksEvent) {
        pushBookmarkedNotices();
      } else if (event == ProfileEvents.feedbackEvent) {
        feedbackHandler();
      } else if (event == ProfileEvents.notificationSettingsEvent) {
        notificationSettingsHandler();
      } else if (event == ProfileEvents.aboutUsEvent) {
        aboutUsHandler();
      }
    });
  }

  void pushBookmarkedNotices() {
    ListNoticeMetaData bookmarkListNoticeMetaData = ListNoticeMetaData(
        appBarLabel: 'Bookmarked Notices',
        dynamicFetch: DynamicFetch.fetchBookmarkedNotices,
        noFilters: true,
        isSearch: false);
    previousRoute = profileRoute;
    navigatorKey.currentState!
        .pushNamed(listNoticesRoute, arguments: bookmarkListNoticeMetaData);
  }

  Future<void> feedbackHandler() => _openGitHub('/issues');

  Future<void> _openGitHub(String path) async {
    await launchUrl(
      Uri.https('github.com', '/HUKA-Taro/noticeboard_v2$path'),
      mode: LaunchMode.externalApplication,
    );
  }

  void notificationSettingsHandler() async {
    const url = '${BASE_URL}settings/manage_notifications';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> aboutUsHandler() => _openGitHub('');

  void disposeStreams() {
    _eventController.close();
  }
}
