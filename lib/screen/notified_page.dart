import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class NotifiedPage extends StatelessWidget {
  final String? label;

  const NotifiedPage({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    // แยก payload และตรวจสอบขนาด
    final parts = label?.toString().split("|") ?? ["No Title", "No Description", "N/A", "N/A"];
    final title = parts.isNotEmpty ? parts[0] : "No Title";
    final description = parts.length > 1 ? parts[1] : "No Description";
    final startTime = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : "N/A";
    final endTime = parts.length > 3 && parts[3].isNotEmpty ? parts[3] : "N/A";

    print("NotifiedPage - Title: $title, Description: $description, StartTime: $startTime, EndTime: $endTime");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Get.isDarkMode ? Colors.grey[800] : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Get.isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Event Details",
          style: GoogleFonts.poppins(
            color: Get.isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Get.isDarkMode
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [Colors.blue[50]!, Colors.blue[100]!],
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Get.isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: Get.isDarkMode ? Colors.blue[300] : Colors.blue[700],
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Get.isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Description
                Text(
                  "Description",
                  style: GoogleFonts.poppins(
                    color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    color: Get.isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                // Start Time
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Get.isDarkMode ? Colors.blue[300] : Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Start Time: $startTime",
                      style: GoogleFonts.poppins(
                        color: Get.isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // End Time
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      color: Get.isDarkMode ? Colors.blue[300] : Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "End Time: $endTime",
                      style: GoogleFonts.poppins(
                        color: Get.isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}