import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/calendar_event.dart';
import '../../utils/calendar_functions.dart';

const double stationListMaxHeight = 290;

@visibleForTesting
bool eventDialogsDebugBypassFirebase = false; // when true skip Firestore/Auth side effects

Future<void> showAddEventDialog({
  required BuildContext context,
  required DateTime day,
  required int startIndex,
  int? endIndex,
  required List<String> stationNames,
  required List<int> hours,
  required List<CalendarEvent> events,
  required Function(CalendarEvent) onEventAdded,
}) async {
  final localizations = AppLocalizations.of(context);
  String departureStation = '';
  String arrivalStation = '';
  bool isSaving = false;
  String? stationError; // <-- aggiungi variabile errore
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Theme.of(context).dialogTheme.backgroundColor ?? Theme.of(context).colorScheme.surfaceContainer,
          title: Row(
            children: [
              Icon(Icons.event, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(localizations.translate('new_event')),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: localizations.translate('cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return stationNames.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      departureStation = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      controller.text = departureStation;
                      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: localizations.translate('departure'),
                        ),
                        onChanged: (value) {
                          departureStation = value;
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: SizedBox(
                            width: 257,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: stationListMaxHeight),
                              child: ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                children: options.map((option) {
                                  return ListTile(
                                    title: Text(option),
                                    onTap: () => onSelected(option),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return stationNames.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      arrivalStation = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      controller.text = arrivalStation;
                      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: localizations.translate('arrival'),
                        ),
                        onChanged: (value) {
                          arrivalStation = value;
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: SizedBox(
                            width: 257,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: stationListMaxHeight),
                              child: ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                children: options.map((option) {
                                  return ListTile(
                                    title: Text(option),
                                    onTap: () => onSelected(option),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const SizedBox(width: 7),
                    Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 7),
                    Icon(Icons.access_time, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 7),
                    Icon(Icons.access_time_filled, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
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
                const SizedBox(height: 10),
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
                    Icon(Icons.repeat, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(localizations.translate('recurrent')),
                  ],
                ),
                if (isRecurrent)
                  Row(
                    children: [
                      const SizedBox(width: 7),
                      Icon(Icons.event_repeat, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: CircularProgressIndicator(),
                  ),
                if (stationError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                    child: Text(
                      stationError!,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.red[300]
                            : Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          actions: [
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () async {
                  if (!stationNames.contains(departureStation) ||
                      !stationNames.contains(arrivalStation)) {
                    setStateDialog(() {
                      stationError = localizations.translate('invalid_station_name');
                    });
                    return;
                  }
                  if (departureStation.isEmpty || arrivalStation.isEmpty) {
                    return;
                  }
                  setStateDialog(() {
                    isSaving = true;
                    stationError = null;
                  });

                  if (!eventDialogsDebugBypassFirebase) {
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
                    } else {
                      onEventAdded(CalendarEvent(
                        date: day,
                        hour: startSlot,
                        endHour: selectedEndSlot,
                        departureStation: departureStation,
                        arrivalStation: arrivalStation,
                        isRecurrent: isRecurrent,
                        recurrenceEndDate: recurrenceEndDate,
                      ));
                    }
                  } else {
                    onEventAdded(CalendarEvent(
                      date: day,
                      hour: startSlot,
                      endHour: selectedEndSlot,
                      departureStation: departureStation,
                      arrivalStation: arrivalStation,
                      isRecurrent: isRecurrent,
                      recurrenceEndDate: recurrenceEndDate,
                    ));
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                label: Text(localizations.translate('save')),
              ),
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
  required List<String> stationNames,
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

  String? stationError; // <-- aggiungi variabile errore

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Theme.of(context).dialogTheme.backgroundColor ?? Theme.of(context).colorScheme.surfaceContainer,
          title: Row(
            children: [
              Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(localizations.translate('edit_event')),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: localizations.translate('cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Autocomplete<String>(
                    initialValue: TextEditingValue(text: departureStation),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return stationNames.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      departureStation = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      controller.text = departureStation;
                      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: localizations.translate('departure_station'),
                        ),
                        onChanged: (value) {
                          departureStation = value;
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: SizedBox(
                            width: 257,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: stationListMaxHeight),
                              child: ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                children: options.map((option) {
                                  return ListTile(
                                    title: Text(option),
                                    onTap: () => onSelected(option),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Autocomplete<String>(
                    initialValue: TextEditingValue(text: arrivalStation),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return stationNames.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      arrivalStation = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      controller.text = arrivalStation;
                      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: localizations.translate('arrival_station'),
                        ),
                        onChanged: (value) {
                          arrivalStation = value;
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: SizedBox(
                            width: 257,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: stationListMaxHeight),
                              child: ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                children: options.map((option) {
                                  return ListTile(
                                    title: Text(option),
                                    onTap: () => onSelected(option),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const SizedBox(width: 7),
                    Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 7),
                    Icon(Icons.access_time, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 7),
                    Icon(Icons.access_time_filled, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
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
                const SizedBox(height: 10),
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
                    Icon(Icons.repeat, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(localizations.translate('recurrent')),
                  ],
                ),
                if (isRecurrent)
                  Row(
                    children: [
                      const SizedBox(width: 7),
                      Icon(Icons.event_repeat, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
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
                if (stationError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                    child: Text(
                      stationError!,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.red[300]
                            : Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () async {
                if (!stationNames.contains(departureStation) ||
                    !stationNames.contains(arrivalStation)) {
                  setStateDialog(() {
                    stationError = localizations.translate('invalid_station_name');
                  });
                  return;
                }
                if (departureStation.isEmpty || arrivalStation.isEmpty) {
                  return;
                }
                stationError = null;

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

                  if(selectedDay == event.date){
                    selectedDay = generatorEvent.date;
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

                if (!eventDialogsDebugBypassFirebase) {
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
                }
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              label: Text(localizations.translate('save')),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
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
                  if (!eventDialogsDebugBypassFirebase) {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users/${user.uid}/events')
                          .doc(generatorEvent.id)
                          .delete();
                    }
                  }
                  if (context.mounted) Navigator.pop(context);
                }
              },
              label: Text(localizations.translate('delete')),
            ),
          ],
        );
      });
    },
  );
}
