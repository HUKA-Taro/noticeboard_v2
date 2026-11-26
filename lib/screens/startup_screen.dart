import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../global/global_functions.dart';
import '../shared/app_theme.dart';
import '../styles/launching_constants.dart';
import '../styles/login_constants.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: mainLaunchingLogo(size.width, size.height),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 80,
                child: Semantics(
                  label: 'Starting Noticeboard',
                  child: spinner(),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: startupCredit(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
