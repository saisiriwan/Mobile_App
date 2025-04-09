import 'dart:async';
import 'dart:collection';
import 'package:calendar_app/component/appBar.dart';
import 'package:calendar_app/component/button.dart';
import 'package:calendar_app/component/eventList.dart';
import 'package:calendar_app/component/theme/theme.dart';
import 'package:calendar_app/screen/addpage.dart';
import 'package:calendar_app/screen/editpage.dart';
import 'package:calendar_app/services/notification_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/event.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ตัวแปรสำหรับจัดการปฏิทินและเหตุการณ์
  late DateTime _focusedDay;
  late DateTime _firstDay;
  late DateTime _lastDay;
  late DateTime _selectedDay;
  late CalendarFormat _calendarFormat;
  late Map<DateTime, List<Event>> _events;
  late StreamSubscription<QuerySnapshot<Event>> _eventSubscription;
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _initializeCalendar();
    _initializeEvents();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _eventSubscription.cancel();
    super.dispose();
  }

  /// ตั้งค่าเริ่มต้นสำหรับปฏิทิน
  void _initializeCalendar() {
    _focusedDay = DateTime.now();
    _firstDay = DateTime.now().subtract(const Duration(days: 1000));
    _lastDay = DateTime.now().add(const Duration(days: 1000));
    _selectedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;
  }

  /// ตั้งค่าเริ่มต้นสำหรับเหตุการณ์
  void _initializeEvents() {
    _events = LinkedHashMap(
      equals: isSameDay,
      hashCode: _getHashCode,
    );
    _loadEvents();
  }

  /// ตั้งค่าเริ่มต้นสำหรับการแจ้งเตือน
  void _initializeNotifications() {
    _notificationService = NotificationService();
    _notificationService.initializeNotification();
    _notificationService.requestIOSPermissions();
    _notificationService.initializeWorkManager();
  }

  /// คำนวณ hash code สำหรับ DateTime
  int _getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }

  /// โหลดเหตุการณ์จาก Firestore
  Future<void> _loadEvents() async {
    final firstDay = Timestamp.fromDate(DateTime(_focusedDay.year, _focusedDay.month, 1));
    final lastDay = Timestamp.fromDate(DateTime(_focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59));
    print("Loading events from $firstDay to $lastDay");

    _events.clear();
    final eventStream = FirebaseFirestore.instance
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: firstDay)
        .where('date', isLessThanOrEqualTo: lastDay)
        .withConverter(
          fromFirestore: Event.fromFirestore,
          toFirestore: (event, options) => event.ToFirestore(),
        )
        .snapshots();

    _eventSubscription = eventStream.listen(
      (snapshot) {
        _events.clear();
        for (var doc in snapshot.docs) {
          final event = doc.data();
          final day = DateTime(event.date!.year, event.date!.month, event.date!.day);
          _events.putIfAbsent(day, () => []).add(event);
        }
        print("Events Loaded: ${_events.length} days with events");
        setState(() {});
      },
      onError: (error) => print("Error loading events: $error"),
    );
  }

  /// ดึงรายการเหตุการณ์สำหรับวันที่ระบุ
  List<Event> _eventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  /// นำทางไปยังหน้าเพิ่มเหตุการณ์
  Future<void> _toAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Addpage(
          firstDate: _firstDay,
          lastDate: _lastDay,
          selectedDate: _selectedDay,
        ),
      ),
    );
    if (result == true) {
      _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Appbar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildHeader(),
          const SizedBox(height: 10),
          _buildCalendar(),
          const SizedBox(height: 25),
          _buildTaskSection(),
          const SizedBox(height: 10),
          _buildEventList(),
        ],
      ),
    );
  }

  /// สร้างส่วนหัวที่มีวันที่และปุ่มล้างการแจ้งเตือน
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat.yMMMMd().format(DateTime.now()),
            style: subHeadingStyle,
          ),
        ],
      ),
    );
  }

  /// สร้างปฏิทิน
  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: TableCalendar(
          eventLoader: _eventsForDay,
          focusedDay: _focusedDay,
          firstDay: _firstDay,
          lastDay: _lastDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
              _selectedDay = focusedDay;
            });
            _eventSubscription.cancel();
            _loadEvents();
          },
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarFormat: _calendarFormat,
          availableCalendarFormats: const {
            CalendarFormat.week: 'Week',
            CalendarFormat.month: 'Month',
            CalendarFormat.twoWeeks: '2 Weeks',
          },
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          headerStyle: const HeaderStyle(
            titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            formatButtonDecoration: BoxDecoration(
              color: Colors.orangeAccent,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            formatButtonTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            titleCentered: true,
            leftChevronIcon: Icon(Icons.chevron_left),
            rightChevronIcon: Icon(Icons.chevron_right),
          ),
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
            selectedDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
            todayDecoration: BoxDecoration(color: Colors.deepOrangeAccent, shape: BoxShape.circle),
            todayTextStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
            weekendStyle: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  /// สร้างส่วนหัวของรายการงาน
  Widget _buildTaskSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text("Task List", style: HeadingStyle),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Button(label: "Add Task", tap: _toAddPage),
        ),
      ],
    );
  }

  /// สร้างรายการเหตุการณ์
  Widget _buildEventList() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ListView.builder(
          itemCount: _eventsForDay(_selectedDay).length,
          itemBuilder: (context, index) {
            final event = _eventsForDay(_selectedDay)[index];
            _scheduleDailyNotification(event);
            return _buildAnimatedEvent(event, index);
          },
        ),
      ),
    );
  }

  /// ตั้งการแจ้งเตือนสำหรับเหตุการณ์ประจำวัน
  void _scheduleDailyNotification(Event event) {
    try {
      // ตรวจสอบ startTime
      if (event.startTime == null || event.startTime!.trim().isEmpty) {
        print("Error: startTime is null or empty");
        return;
      }

      final startTime = event.startTime!.trim();
      print("Raw startTime: $startTime");
      final date = DateFormat("hh:mm a").parse(startTime);
      final myTime = DateFormat("HH:mm").format(date);
      print("Formatted time: $myTime");
      final hour = int.parse(myTime.split(":")[0]);
      final minute = int.parse(myTime.split(":")[1]);
      print("hour: $hour, minute: $minute");
      print("Event data: ${event.toString()}");

      // ตรวจสอบ endTime
      final endTime = event.endTime?.trim() ?? "N/A";
      print("Raw endTime: $endTime");

      _notificationService.scheduledNotification(
        hour,
        minute,
        event,
        startTime: startTime, // ส่ง startTime ในรูปแบบ "9:18 AM"
        endTime: endTime,
      );
    } catch (e) {
      print("Error parsing time: $e");
    }
  }
  
  /// สร้างแอนิเมชันสำหรับรายการเหตุการณ์
  Widget _buildAnimatedEvent(Event event, int index) {
    return AnimationConfiguration.staggeredList(
      position: index,
      child: SlideAnimation(
        child: FadeInAnimation(
          child: GestureDetector(
            onTap: () => _showBottomSheet(context, event),
            child: EventList(
              event: event,
              Delete: () => _deleteEvent(event),
              Edit: () => _editEvent(event),
            ),
          ),
        ),
      ),
    );
  }

  /// แสดง BottomSheet สำหรับตัวเลือกเหตุการณ์
  void _showBottomSheet(BuildContext context, Event event) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(top: 4),
        height: event.isSucceed == 1
            ? MediaQuery.of(context).size.height * 0.24
            : MediaQuery.of(context).size.height * 0.32,
        width: MediaQuery.of(context).size.width,
        color: Get.isDarkMode ? darkGreyClr : Colors.white,
        child: Column(
          children: [
            Container(
              height: 6,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Get.isDarkMode ? Colors.grey[600] : Colors.grey[300],
              ),
            ),
            const Spacer(),
            if (event.isSucceed != 1)
              _buildBottomSheetButton(
                label: "Successed",
                onTap: () => _successEvent(event),
                color: primaryClr,
                context: context,
              ),
            _buildBottomSheetButton(
              label: "Delete Event",
              onTap: () => _deleteEvent(event),
              color: Colors.red[300]!,
              context: context,
            ),
            if (event.isSucceed != 1)
            _buildBottomSheetButton(
              label: "Edit Event",
              onTap: () => _editEvent(event),
              color: bluishClr,
              context: context,
            ),
            const SizedBox(height: 20),
            _buildBottomSheetButton(
              label: "Close",
              onTap: () => Get.back(),
              color: Colors.red[300]!,
              isClose: true,
              context: context,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// สร้างปุ่มใน BottomSheet
  Widget _buildBottomSheetButton({
    required String label,
    required Function() onTap,
    required Color color,
    bool isClose = false,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        height: 45,
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: isClose
                ? Get.isDarkMode
                    ? Colors.grey[600]!
                    : Colors.grey[300]!
                : color,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isClose ? Colors.transparent : color,
        ),
        child: Center(
          child: Text(
            label,
            style: isClose ? TitleStyle : TitleStyle.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  /// ลบเหตุการณ์
  Future<void> _deleteEvent(Event event) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text("Are you sure you want to delete event?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Yes"),
          ),
        ],
      ),
    );
    if (delete == true) {
      await FirebaseFirestore.instance.collection('events').doc(event.Id).delete();
      _loadEvents();
    }
  }

  /// แก้ไขเหตุการณ์
  Future<void> _editEvent(Event event) async {
    final edit = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => Editpage(
          firstDate: _firstDay,
          lastDate: _lastDay,
          event: event,
        ),
      ),
    );
    if (edit == true) {
      _loadEvents();
    }
  }

  Future<void> _successEvent(Event event) async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(event.Id)
        .update({
      'isSucceed': 1,
    });
  }
}