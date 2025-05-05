import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart';
import 'widgets/train_card.dart'; // Importa il widget TrainCard
import 'widgets/responsive_card_list.dart'; // Importa il widget ResponsiveCardList

class TrainsPage extends StatefulWidget {
  const TrainsPage({super.key});

  @override
  State<TrainsPage> createState() => _TrainsPageState();
}

class _TrainsPageState extends State<TrainsPage> {
  late List<String> daysOfWeekFull;
  late List<String> daysOfWeekShort;
  int selectedDayIndex = 0;
  int? expandedCardIndex; // Indice della card attualmente espansa

  @override
  void initState() {
    super.initState();
    daysOfWeekFull = [];
    daysOfWeekShort = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localizations = AppLocalizations.of(context);
    setState(() {
      daysOfWeekFull = List.generate(7, (index) {
        final now = DateTime.now();
        final day = now.add(Duration(days: index));
        return toBeginningOfSentenceCase(
            DateFormat.EEEE(localizations.languageCode()).format(day))!;
      });

      daysOfWeekShort = List.generate(7, (index) {
        final now = DateTime.now();
        final day = now.add(Duration(days: index));
        return toBeginningOfSentenceCase(
            DateFormat.E(localizations.languageCode()).format(day))!;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final bool showFullDays = screenWidth > 600;
    final daysOfWeek = showFullDays ? daysOfWeekFull : daysOfWeekShort;

    // Dati fittizi per le card (in futuro possono essere caricati da un database)
    final trainData = List.generate(10, (index) {
      return {
        'title': '${localizations.translate('train')} $index',
      };
    });

    // Genera le card
    final trainCards = trainData.asMap().entries.map((entry) {
      final index = entry.key;
      final train = entry.value;

      return TrainCard(
        title: train['title']! as String,
        isExpanded: expandedCardIndex == index,
        onTap: () {
          setState(() {
            expandedCardIndex = expandedCardIndex == index ? null : index;
          });
        },
        departureTime: DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: index))), // Example departure time as String
        arrivalTime: DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: index + 2))), // Example arrival time as String
        isDirect: index % 2 == 0, // Example: even index trains are direct
        userAvatars: [
          {'image': 'images/avatar1.png', 'name': 'Alice', 'from': '1', 'to': '2'},
          {'image': 'images/avatar2.png', 'name': 'Bob', 'from': '2', 'to': '7'},
          {'image': 'images/avatar3.png', 'name': 'Carla', 'from': '3', 'to': '9'},
          {'image': 'images/avatar4.png', 'name': 'David', 'from': '2', 'to': '3'},
          {'image': 'images/avatar5.png', 'name': 'Elena', 'from': '1', 'to': '9'},
        ], // Example list of user avatar objects
        legs: [
          {
            'stops': [
              {
                'name': 'Station A',
                'arrivalTime': DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: index))),
                'departureTime': DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: index, minutes: 10))),
                'platform': '1',
                'track': 'A',
                'id': '1',
              },
              {
                'name': 'Station B',
                'arrivalTime': DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: index + 1))),
                'departureTime': DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: index + 1, minutes: 5))),
                'platform': '2',
                'track': 'B',
                'id': '2',
              },
              {
                'name': 'Station C',
                'arrivalTime': DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: index + 2))),
                'departureTime': null,
                'platform': '3',
                'track': 'C',
                'id': '3',
              },
              {
                'name': 'Station D',
                'arrivalTime': DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: index + 2))),
                'departureTime': DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: index + 2, minutes: 8))),
                'platform': '3',
                'track': 'C',
                'id': '4',
              },
              {
                'name': 'Station E',
                'arrivalTime': DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: index + 2))),
                'departureTime': DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: index + 2, minutes: 8))),
                'platform': '3',
                'track': 'C',
                'id': '5',
              }
            ],
            'trainNumber': 'T${index + 100}',
            'operator': 'TrainCo',
            'isDirect': index % 2 == 0,
          },
          {
            'stops': [
              {
                'name': 'Station X',
                'arrivalTime': DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: index + 3))),
                'departureTime': DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: index + 3, minutes: 8))),
                'platform': '4',
                'track': 'D',
                'id': '7',
              },
              {
                'name': 'Station Y',
                'arrivalTime': DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: index + 4))),
                'departureTime': DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: index + 4, minutes: 6))),
                'platform': '5',
                'track': 'E',
                'id': '8',
              },
              {
                'name': 'Station Z',
                'arrivalTime': DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: index + 5))),
                'departureTime': null,
                'platform': '6',
                'track': 'F',
                'id': '9',
              },
            ],
            'trainNumber': 'T${index + 200}',
            'operator': 'Railways',
            'isDirect': index % 2 != 0,
          }
        ],
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('trains')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Row(
            children: List.generate(daysOfWeek.length, (index) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDayIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    decoration: BoxDecoration(
                      color: selectedDayIndex == index ? Colors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Center(
                      child: Text(
                        daysOfWeek[index],
                        style: TextStyle(
                          color: selectedDayIndex == index ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding to the page
        child: Column(
          children: [
            // Add any other widgets above the list if needed
            Expanded(
              child: ResponsiveCardList(
                cards: trainCards,
                expandedCardIndex: expandedCardIndex, // Pass the expanded card index
              ),
            ),
          ],
        ),
      ),
    );
  }
}
