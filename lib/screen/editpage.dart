import 'package:calendar_app/component/appBarPage.dart';
import 'package:calendar_app/component/button.dart';
import 'package:calendar_app/component/input_field.dart';
import 'package:calendar_app/component/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:calendar_app/model/event.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class Editpage extends StatefulWidget {
  final DateTime firstDate;
  final DateTime lastDate;
  final Event? event;

  const Editpage({
    Key? key,
    required this.firstDate,
    required this.lastDate,
    required this.event,
  }) : super(key: key);

  @override
  State<Editpage> createState() => _EditpageState();
}

class _EditpageState extends State<Editpage> {
  late DateTime _selectedDate;
  late String _endTime;
  late String _startTime;
  late int _selectedRemind;
  late String _selectedRepeat;
  late int _selectedColor;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  List<int> remindList = [0,5, 10, 15,];
  List<String> repeatList = ["None", "Daily", "Weekly", "Monthly"];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.event?.date ?? DateTime.now();
    _titleController = TextEditingController(text: widget.event?.title ?? "");
    _descriptionController =
        TextEditingController(text: widget.event?.description ?? "");
    _startTime = widget.event!.startTime ??
        DateFormat('hh:mm a').format(DateTime.now()).toString();
    _endTime = widget.event!.endTime ?? "9.30 PM";
    _selectedRemind = widget.event!.remind ?? 5;
    _selectedRepeat = widget.event!.repeat ?? "None";
    _selectedColor = widget.event!.Color ?? 0;
  }

  void _checkDateEvent() async {
    if (_titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty) {
      _saveEvent();
      Navigator.of(context).pop(true);
    } else if (_descriptionController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      Get.snackbar(
        "Required",
        "All fields are required!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: pinkClr,
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.red,
        ),
        duration: const Duration(seconds: 5),
      );
    }
  }

  void _saveEvent() async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event?.Id)
        .update({
      'date': Timestamp.fromDate(_selectedDate),
      'title': _titleController.text,
      'description': _descriptionController.text,
      'startTime': _startTime,
      'endTime': _endTime,
      'isSucceed': widget.event!.isSucceed,
      'Color': _selectedColor,
      'remind': _selectedRemind,
      'repeat': _selectedRepeat,
    });
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const AppbarPage(),
        body: Container(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Edit Task", style: HeadingStyle),
                InputField(
                  title: "Title",
                  hint: "Enter your Title",
                  controller: _titleController,
                ),
                InputField(
                  title: "Description",
                  hint: "Enter your Description",
                  controller: _descriptionController,
                ),
                InputField(
                  title: "Date",
                  hint: DateFormat.yMd().format(_selectedDate),
                  widget: IconButton(
                    onPressed: () {
                      _getDate();
                    },
                    icon: const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                        flex: 1,
                        child: InputField(
                          title: "Start Time",
                          hint: _startTime,
                          widget: IconButton(
                            onPressed: () {
                              _getTime(isStartTime: true);
                            },
                            icon: const Icon(
                              Icons.access_time_rounded,
                              color: Colors.grey,
                            ),
                          ),
                        )),
                    const SizedBox(
                      width: 15,
                    ),
                    Expanded(
                        flex: 1,
                        child: InputField(
                          title: "End Time",
                          hint: _endTime,
                          widget: IconButton(
                            onPressed: () {
                              _getTime(isStartTime: false);
                            },
                            icon: const Icon(
                              Icons.access_time_rounded,
                              color: Colors.grey,
                            ),
                          ),
                        )),
                  ],
                ),
                InputField(
                  title: "Remind",
                  hint: "$_selectedRemind minutes early",
                  widget: DropdownButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                      iconSize: 32,
                      elevation: 4,
                      style: SubTitleStyle,
                      underline: Container(
                        height: 0,
                      ),
                      items:
                          remindList.map<DropdownMenuItem<String>>((int value) {
                        return DropdownMenuItem<String>(
                          value: value.toString(),
                          child: Text(value.toString()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRemind = int.parse(newValue!);
                        });
                      }),
                ),
                InputField(
                  title: "Repeat",
                  hint: "$_selectedRepeat",
                  widget: DropdownButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                      iconSize: 32,
                      elevation: 4,
                      style: SubTitleStyle,
                      underline: Container(
                        height: 0,
                      ),
                      items: repeatList
                          .map<DropdownMenuItem<String>>((String? value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(
                            value!,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRepeat = newValue!;
                        });
                      }),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _colorPallte(),
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      child:
                          Button(label: "Save", tap: () => _checkDateEvent()),
                    )
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  _getDate() async {
    DateTime? _pickerDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );

    if (mounted && _pickerDate != null) {
      setState(() {
        _selectedDate = _pickerDate;
        print(_selectedDate);
      });
    }
  }

  _getTime({required bool isStartTime}) async {
    var pickedTime = await _showTimePicker();
    String formatedTime = pickedTime.format(context);
    if (pickedTime == null) {
      print("Time canceled");
    } else if (isStartTime) {
      setState(() {
        _startTime = formatedTime;
      });
    } else if (!isStartTime) {
      setState(() {
        _endTime = formatedTime;
      });
    }
  }

  _showTimePicker() {
    return showTimePicker(
        context: context,
        initialEntryMode: TimePickerEntryMode.input,
        initialTime: TimeOfDay(
          hour: int.parse(_startTime.split(":")[0]),
          minute: int.parse(_startTime.split(":")[1].split(" ")[0]),
        ));
  }

  _colorPallte() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "Color",
        style: TitleStyle,
      ),
      const SizedBox(
        height: 8,
      ),
      Wrap(
        children: List<Widget>.generate(6, (int index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = index;
              });
            },
            child: Padding(
              padding: EdgeInsets.only(right: 6.0),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: index == 0
                    ? redClr
                    : index == 1
                        ? orangeClr
                        : index == 2
                            ? greenClr
                            : index == 3
                                ? lightBlueClr
                                : index == 4
                                    ? blueClr
                                    : pinkClr,
                child: _selectedColor == index
                    ? const Icon(
                        Icons.done,
                        color: Colors.white,
                        size: 16,
                      )
                    : Container(),
              ),
            ),
          );
        }),
      ),
    ]);
  }
}
