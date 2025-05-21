import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/calendar_event.dart';
import '../utils/calendar_functions.dart';

Future<void> showAddEventDialog({
  required BuildContext context,
  required DateTime day,
  required int startIndex,
  int? endIndex,
  required List<int> hours,
  required List<CalendarEvent> events,
  required Function(CalendarEvent) onEventAdded,
}) async {
  final localizations = AppLocalizations.of(context);
  String departureStation = '';
  String arrivalStation = '';
  bool isSaving = false;
  int safeStart = startIndex.clamp(0, hours.length - 1);
  int startSlot = safeStart;
  int selectedEndSlot = endIndex ?? startSlot + 1;

  List<int> availableEndHours = getAvailableEndHours(day, startSlot);

  bool isRecurrent = false;
  DateTime? recurrenceEndDate = day.add(const Duration(days: 7));

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: Text(localizations.translate('new_event')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                    hintText: localizations.translate('departure_station')),
                onChanged: (value) {
                  departureStation = value;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                    hintText: localizations.translate('arrival_station')),
                onChanged: (value) {
                  arrivalStation = value;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('${localizations.translate('day')}: '),
                  TextButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: day,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setStateDialog(() {
                          day = pickedDate;
                        });
                      }
                    },
                    child: Text(
                        DateFormat('EEE, MMM d', localizations.languageCode())
                            .format(day)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('${localizations.translate('start_hour')}: '),
                  DropdownButton<int>(
                    value: startSlot,
                    items: hours
                        .map((slot) => DropdownMenuItem(
                              value: slot,
                              child: Text(formatTime(slot)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() {
                          startSlot = value;
                          availableEndHours = getAvailableEndHours(
                              day, startSlot);
                          if (!availableEndHours
                              .contains(selectedEndSlot)) {
                            selectedEndSlot = availableEndHours.isNotEmpty
                                ? availableEndHours.first
                                : 1;
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('${localizations.translate('end_hour')}: '),
                  DropdownButton<int>(
                    value: selectedEndSlot,
                    items: availableEndHours
                        .map((slot) => DropdownMenuItem(
                              value: slot,
                              child: Text(formatTime(slot)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() {
                          selectedEndSlot = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: isRecurrent,
                    onChanged: (value) {
                      setStateDialog(() {
                        isRecurrent = value ?? false;
                      });
                    },
                  ),
                  Text(localizations.translate('recurrent')),
                ],
              ),
              if (isRecurrent)
                Row(
                  children: [
                    Text('${localizations.translate('end_recurrence')}: '),
                    TextButton(
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: recurrenceEndDate ?? day,
                          firstDate: day,
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          setStateDialog(() {
                            recurrenceEndDate = pickedDate;
                          });
                        }
                      },
                      child: Text(recurrenceEndDate != null
                          ? DateFormat('EEE, MMM d', localizations.languageCode())
                              .format(recurrenceEndDate!)
                          : localizations.translate('select_date')),
                    ),
                  ],
                ),
              if (isSaving)
                const CircularProgressIndicator(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (departureStation.isEmpty || arrivalStation.isEmpty) {
                  return;
                }
                setStateDialog(() {
                  isSaving = true;
                });

                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final eventsCollection = FirebaseFirestore.instance.collection('users/${user.uid}/events');
                  final eventStart = DateTime(
                    day.year, day.month, day.day,
                    6 + (startSlot ~/ 4),
                    (startSlot % 4) * 15,
                  );
                  final eventEnd = DateTime(
                    day.year, day.month, day.day,
                    6 + (selectedEndSlot ~/ 4),
                    (selectedEndSlot % 4) * 15,
                  );
                  final eventData = {
                    'origin': departureStation,
                    'destination': arrivalStation,
                    'event_start': Timestamp.fromDate(eventStart),
                    'event_end': Timestamp.fromDate(eventEnd),
                    'recurrence_end': isRecurrent && recurrenceEndDate != null
                        ? Timestamp.fromDate(recurrenceEndDate!)
                        : null,
                    'recurrent': isRecurrent,
                  };
                  final newEventRef = await eventsCollection.add(eventData);
                  final newEventId = newEventRef.id;
                  onEventAdded(CalendarEvent(
                    id: newEventId,
                    date: day,
                    hour: startSlot,
                    endHour: selectedEndSlot,
                    departureStation: departureStation,
                    arrivalStation: arrivalStation,
                    isRecurrent: isRecurrent,
                    recurrenceEndDate: recurrenceEndDate,
                  ));
                }

                Navigator.pop(context);
              },
              child: Text(localizations.translate('save')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(localizations.translate('cancel')),
            ),
          ],
        );
      });
    },
  );
}

Future<void> showEditEventDialog({
  required BuildContext context,
  required CalendarEvent event,
  required List<int> hours,
  required List<CalendarEvent> events,
  required VoidCallback onEventUpdated,
  required Function(String) onEventDeleted,
}) async {
  final localizations = AppLocalizations.of(context);
  String departureStation = event.departureStation;
  String arrivalStation = event.arrivalStation;
  DateTime selectedDay = event.date;
  int selectedStartSlot = event.hour;
  int selectedEndSlot = event.endHour;
  List<int> availableEndHours = getAvailableEndHours(event.date, selectedStartSlot, event);

  bool isRecurrent = event.isRecurrent;
  DateTime? recurrenceEndDate = event.recurrenceEndDate ?? event.date.add(const Duration(days: 7));

  CalendarEvent? generatorEvent = event.generatedBy != null
      ? events.firstWhere((e) => e.id == event.generatedBy, orElse: () => event)
      : event;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: Text(localizations.translate('edit_event')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: departureStation),
                decoration: InputDecoration(
                    hintText: localizations.translate('departure_station')),
                onChanged: (value) {
                  departureStation = value;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: TextEditingController(text: arrivalStation),
                decoration: InputDecoration(
                    hintText: localizations.translate('arrival_station')),
                onChanged: (value) {
                  arrivalStation = value;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('${localizations.translate('day')}: '),
                  TextButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDay,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setStateDialog(() {
                          selectedDay = pickedDate;
                        });
                      }
                    },
                    child: Text(
                        DateFormat('EEE, MMM d', localizations.languageCode())
                            .format(selectedDay)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('${localizations.translate('start_hour')}: '),
                  DropdownButton<int>(
                    value: selectedStartSlot,
                    items: hours
                        .map((slot) => DropdownMenuItem(
                              value: slot,
                              child: Text(formatTime(slot)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() {
                          selectedStartSlot = value;
                          availableEndHours = getAvailableEndHours(
                              selectedDay, selectedStartSlot, event);
                          if (!availableEndHours.contains(selectedEndSlot)) {
                            selectedEndSlot = availableEndHours.isNotEmpty
                                ? availableEndHours.first
                                : 1;
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('${localizations.translate('end_hour')}: '),
                  DropdownButton<int>(
                    value: selectedEndSlot,
                    items: availableEndHours
                        .map((slot) => DropdownMenuItem(
                              value: slot,
                              child: Text(formatTime(slot)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() {
                          selectedEndSlot = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: isRecurrent,
                    onChanged: (value) {
                      setStateDialog(() {
                        isRecurrent = value ?? false;
                      });
                    },
                  ),
                  Text(localizations.translate('recurrent')),
                ],
              ),
              if (isRecurrent)
                Row(
                  children: [
                    Text('${localizations.translate('end_recurrence')}: '),
                    TextButton(
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: recurrenceEndDate ?? selectedDay,
                          firstDate: selectedDay,
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          setStateDialog(() {
                            recurrenceEndDate = pickedDate;
                          });
                        }
                      },
                      child: Text(recurrenceEndDate != null
                          ? DateFormat('EEE, MMM d', localizations.languageCode())
                              .format(recurrenceEndDate!)
                          : localizations.translate('select_date')),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (departureStation.isEmpty || arrivalStation.isEmpty) {
                  return;
                }
                if (isRecurrent) {
                  generatorEvent.isRecurrent = true;
                  generatorEvent.recurrenceEndDate = recurrenceEndDate;
                  generatorEvent.departureStation = departureStation;
                  generatorEvent.arrivalStation = arrivalStation;
                  generatorEvent.hour = selectedStartSlot;
                  generatorEvent.endHour = selectedEndSlot;
                  for (var e in events) {
                    if (e.generatedBy == generatorEvent.id) {
                      e.departureStation = departureStation;
                      e.arrivalStation = arrivalStation;
                      e.hour = selectedStartSlot;
                      e.endHour = selectedEndSlot;
                      e.recurrenceEndDate = recurrenceEndDate;
                    }
                  }
                } else {
                  generatorEvent.departureStation = departureStation;
                  generatorEvent.arrivalStation = arrivalStation;
                  generatorEvent.date = selectedDay;
                  generatorEvent.hour = selectedStartSlot;
                  generatorEvent.endHour = selectedEndSlot;
                  generatorEvent.isRecurrent = false;
                  generatorEvent.recurrenceEndDate = null;
                }
                onEventUpdated();

                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final eventDoc = FirebaseFirestore.instance
                      .collection('users/${user.uid}/events')
                      .doc(generatorEvent.id);
                  final eventStart = DateTime(
                    selectedDay.year, selectedDay.month, selectedDay.day,
                    6 + (selectedStartSlot ~/ 4),
                    (selectedStartSlot % 4) * 15,
                  );
                  final eventEnd = DateTime(
                    selectedDay.year, selectedDay.month, selectedDay.day,
                    6 + (selectedEndSlot ~/ 4),
                    (selectedEndSlot % 4) * 15,
                  );
                  await eventDoc.update({
                    'origin': departureStation,
                    'destination': arrivalStation,
                    'event_start': Timestamp.fromDate(eventStart),
                    'event_end': Timestamp.fromDate(eventEnd),
                    'recurrence_end': isRecurrent && recurrenceEndDate != null
                        ? Timestamp.fromDate(recurrenceEndDate!)
                        : null,
                    'recurrent': isRecurrent,
                  });
                }

                Navigator.pop(context);
              },
              child: Text(localizations.translate('save')),
            ),
            TextButton(
              onPressed: () async {
                bool confirmDelete = await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(localizations.translate('confirm_delete')),
                      content: Text(localizations
                          .translate('delete_event_confirmation')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(localizations.translate('yes')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(localizations.translate('no')),
                        ),
                      ],
                    );
                  },
                );
                if (confirmDelete) {
                  onEventDeleted(generatorEvent.id);
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('users/${user.uid}/events')
                        .doc(generatorEvent.id)
                        .delete();
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(localizations.translate('delete')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.translate('cancel')),
            ),
          ],
        );
      });
    },
  );
}
