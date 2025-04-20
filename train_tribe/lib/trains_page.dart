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
        'details': '${localizations.translate('details_about')} ${localizations.translate('train')} $index',
        'additionalDetails': '${localizations.translate('additional_details')} for ${localizations.translate('train')} $index',
        'image': 'images/djungelskog.jpg', // Percorso immagine fittizio
        'list': ['Stop 1', 'Stop 2', 'Stop 3'], // Lista fittizia
      };
    });

    // Genera le card
    final trainCards = trainData.asMap().entries.map((entry) {
      final index = entry.key;
      final train = entry.value;

      return TrainCard(
        title: train['title']! as String,
        details: train['details']! as String,
        additionalDetails: train['additionalDetails']! as String,
        image: train['image']! as String,
        list: train['list']! as List<String>,
        isExpanded: expandedCardIndex == index,
        onTap: () {
          setState(() {
            expandedCardIndex = expandedCardIndex == index ? null : index;
          });
        },
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
