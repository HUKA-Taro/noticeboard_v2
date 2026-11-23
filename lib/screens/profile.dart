import '../shared/profile_app_update.dart';

import 'package:flutter/material.dart';
import 'package:noticeboard/global/global_constants.dart';
import 'package:noticeboard/global/global_functions.dart';
import 'package:noticeboard/models/user_profile.dart';
import 'package:noticeboard/routes/routing_constants.dart';
import '../styles/profile_constants.dart';
import '../bloc/profile_bloc.dart';
import '../enum/profile_enum.dart';
import '../services/auth/auth_repository.dart';

import '../services/notifications/custom_push_service.dart';
import '../services/notifications/notification_settings.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final ProfileBloc _profileBloc = ProfileBloc();
  final AuthRepository _authRepository = AuthRepository();
  @override
  void initState() {
    _profileBloc.context = context;
    super.initState();
  }

  @override
  void dispose() {
    _profileBloc.disposeStreams();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double _width = MediaQuery.of(context).size.width;
    final double _height = MediaQuery.of(context).size.height;

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: screenPopIcon(Colors.black),
            onPressed: () {
              previousRoute = profileRoute;
              navigatorKey.currentState!.pop(context);
            },
          ),
          backgroundColor: globalWhiteColor,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Container(
              width: _width * 0.84,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    constraints: BoxConstraints(minHeight: _height * 0.28),
                    child: FutureBuilder<UserProfile>(
                        future: _authRepository.fetchProfileFromStorage(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 100.0,
                                  height: 100.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(50.0),
                                    child: buildProfilePic(snapshot),
                                  ),
                                ),
                                sizedBox(10.0),
                                noOverFlowTextContainer(
                                    _width,
                                    snapshot.data!.fullName!,
                                    blackSuperBoldMediumSizeText),
                                sizedBox(10.0),
                                noOverFlowTextContainer(
                                    _width,
                                    snapshot.data!.degreeName!,
                                    lightGreySmallSizeText),
                                sizedBox(5.0),
                                noOverFlowTextContainer(
                                    _width,
                                    snapshot.data!.currentYear!,
                                    lightGreySmallSizeText),
                                sizedBox(5.0),
                                noOverFlowTextContainer(
                                    _width,
                                    snapshot.data!.branchName!,
                                    lightGreySmallSizeText)
                              ],
                            );
                          } else if (snapshot.hasError) {
                            return errorFetchingProfile(
                                snapshot.error as String);
                          }
                          return inProgress;
                        }),
                  ),
                  sizedBox(40.0),
                  buildMenuItem(
                      bookmarkIcon, 'Bookmarks', ProfileEvents.bookmarksEvent),
                  sizedBox(20.0),
                  divider(_width),
                  sizedBox(20.0),
                  buildMenuItem(
                      feedbackIcon, 'Feedback', ProfileEvents.feedbackEvent),
                  sizedBox(20.0),
                  if (CustomPushService.supported)
                    _profileNotificationItem(
                      icon: Icons.settings,
                      title: 'Notification settings',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const NotificationSettings(),
                      )),
                    ),
                  sizedBox(20.0),
                  buildMenuItem(
                      aboutUsIcon, "About us", ProfileEvents.aboutUsEvent),
                  sizedBox(20.0),
                  buildMenuItem(
                      logoutIcon, 'Logout', ProfileEvents.logoutEvent),
                  const ProfileAppUpdate(),
                ],
              ),
            ),
          ),
        ));
  }

  GestureDetector buildMenuItem(Icon icon, String text, ProfileEvents event) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _profileBloc.eventSink.add(event);
      },
      child: Row(
        children: [
          icon,
          SizedBox(
            width: 15.0,
          ),
          Text(
            text,
            style: boldMediumGreyMediumSizeText,
          )
        ],
      ),
    );
  }

  Widget _profileNotificationItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: notificationSettingsIcon.color),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: boldMediumGreyMediumSizeText),
                  if (subtitle != null)
                    Text(subtitle, style: lightGreySmallSizeText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProfilePic(AsyncSnapshot snapshot) {
    if (snapshot.hasData &&
        snapshot.data.picUrl != null &&
        snapshot.data.picUrl != "") {
      return FadeInImage.assetNetwork(
        placeholder: 'assets/images/user1.jpg',
        image: snapshot.data.picUrl,
        fit: BoxFit.fill,
      );
    }

    return Image.asset('assets/images/user1.jpg');
  }
}
