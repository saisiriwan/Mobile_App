import 'package:calendar_app/component/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/event.dart';

class EventList extends StatelessWidget {
  final Event event;
  final Function() Delete;
  final Function() Edit;
  // final Function() bottomSheet;

  const EventList({
    Key? key,
    required this.event,
    required this.Delete,
    required this.Edit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          margin: const EdgeInsets.only(bottom: 10),
          width: MediaQuery.of(context).size.width * 0.975,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _getBGClr(event.Color!),
            ),
            child: Row(
              children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(event.title!,
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )),
                      const SizedBox(height: 12),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: Colors.grey[200],
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${event.startTime} - ${event.endTime}",
                              style: GoogleFonts.lato(
                                textStyle: TextStyle(
                                    fontSize: 13, color: Colors.grey[100]),
                              ),
                            ),
                          ]),
                      const SizedBox(height: 12),
                      Text(event.description ?? "",
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                                fontSize: 15, color: Colors.grey[100]),
                          )),
                    ])),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  height: 60,
                  width: 0.5,
                  color: Colors.grey[200]!.withOpacity(0.7),
                ),
                RotatedBox(
                    quarterTurns: 3,
                    child: FittedBox(
                      child: Text(
                        event.isSucceed == 1 ? "Successed" : "TODO",
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                            color: Colors.grey[100],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ))
              ],
            ),
          )),
    );
  }

  _getBGClr(int no) {
    switch (no) {
      case 0:
        return redClr;
      case 1:
        return orangeClr;
      case 2:
        return greenClr;
      case 3:
        return lightBlueClr;
      case 4:
        return blueClr;
      case 5:
        return pinkClr;
      default:
        return redClr;
    }
  }
}
