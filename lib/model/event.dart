import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Event {
  final String? Id;
  final String? title;
  final String? description;
  final DateTime? date;
  final int? isSucceed;
  final String? startTime;
  final String? endTime;
  final int? Color;
  final int? remind;
  final String? repeat;

  Event({
    this.Id,
    this.title,
    this.description,
    this.date,
    this.startTime,
    this.endTime,
    this.isSucceed,
    this.Color,
    this.remind,
    this.repeat,
  });

  factory Event.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
      [SnapshotOptions? options]) {
    final data = snapshot.data()!;
    return Event(
      Id: snapshot.id,
      title: data['title'],
      description: data['description'],
      date: (data['date'] as Timestamp?)?.toDate(),
      startTime: data['startTime'],
      endTime: data['endTime'],
      isSucceed: data['isSucceed'],
      Color: data['Color'],
      remind: data['remind'],
      repeat: data['repeat'],
    );
  }

  Map<String, dynamic> ToFirestore() {
    return {
      "title": title,
      "description": description,
      "date": Timestamp.fromDate(date!),
      "startTime": startTime,
      "endTime": endTime,
      "isSucceed": isSucceed,
      "Color": Color,
      "remind": remind,
      "repeat": repeat,
    };
  }
}
