import 'package:calendar_app/screen/home_page.dart';
import 'package:calendar_app/services/theme_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppbarPage extends StatelessWidget implements PreferredSizeWidget {
  const AppbarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      leading: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        },
        child: Icon(
          Icons.arrow_back_outlined,
          size: 20,
          color: Get.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      actions: const [
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
