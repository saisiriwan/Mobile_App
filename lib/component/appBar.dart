import 'package:calendar_app/model/event.dart';
import 'package:calendar_app/services/notification_services.dart';
import 'package:calendar_app/services/theme_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Appbar extends StatelessWidget implements PreferredSizeWidget {
  final NotificationService notificationService = NotificationService();
  
  Appbar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      leading: GestureDetector(
        onTap: () {
          ThemeServices().switchTheme();
        },
        child: Icon(
          Get.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
          size: 20,
          color: Get.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      actions: [
        CircleAvatar(
          backgroundImage: AssetImage('assets/beru.jpeg'),
        ),
        SizedBox(
          width: 25,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
