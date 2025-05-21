import 'package:intl/intl.dart';
import '../calendar_page.dart';
import '../models/calendar_event.dart';

List<DateTime> getDays(DateTime startDay, int count) {
  return List.generate(count, (index) => startDay.add(Duration(days: index)));
}

List<DateTime> getWeekDays(DateTime startDay, int count) {
  DateTime monday = startDay.subtract(Duration(days: startDay.weekday - 1));
  return List.generate(count, (index) => monday.add(Duration(days: index)));
}

bool isSameDay(DateTime d1, DateTime d2) {
  return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
}

String formatTime(int slot) {
  int hour = 6 + (slot ~/ 4); // Start from 6:00
  if (hour == 24) hour = 0; // Handle 00:00
  if (hour == 25) hour = 1; // Display 1:00 instead of 25:00
  int minute = (slot % 4) * 15;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

List<int> getAvailableEndHours(DateTime day, int startSlot, [CalendarEvent? excludeEvent]) {
  List<int> availableEndHours = [];
  for (int endSlot = startSlot + 1; endSlot <= 76; endSlot++) {
    availableEndHours.add(endSlot);
  }
  return availableEndHours;
}

bool isWithinRecurrence(DateTime date, CalendarEvent event) {
  if (!event.isRecurrent || event.recurrenceEndDate == null) {
    return false;
  }
  return date.isAfter(event.date.subtract(const Duration(days: 1))) &&
      date.isBefore(event.recurrenceEndDate!.add(const Duration(days: 1)));
}

List<CalendarEvent> generateRecurrentEvents(List<DateTime> visibleDays, List<CalendarEvent> events) {
  List<CalendarEvent> recurrentEvents = [];
  DateTime startOfWeek = visibleDays.first;
  DateTime endOfWeek = visibleDays.last;

  for (var event in events) {
    if (event.isRecurrent && event.recurrenceEndDate != null) {
      if (event.date.isBefore(endOfWeek.add(const Duration(days: 1))) &&
          event.recurrenceEndDate!.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
        DateTime currentDate = event.date;
        while (currentDate.isBefore(event.recurrenceEndDate!.add(const Duration(days: 1)))) {
          if (currentDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              currentDate.isBefore(endOfWeek.add(const Duration(days: 1))) &&
              !isSameDay(currentDate, event.date)) {
            recurrentEvents.add(CalendarEvent(
              date: currentDate,
              hour: event.hour,
              endHour: event.endHour,
              departureStation: event.departureStation,
              arrivalStation: event.arrivalStation,
              isRecurrent: event.isRecurrent,
              recurrenceEndDate: event.recurrenceEndDate,
              generatedBy: event.id,
            ));
          }
          currentDate = currentDate.add(const Duration(days: 7));
        }
      }
    }
  }
  return recurrentEvents;
}
