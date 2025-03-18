import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSwitch = false;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Spacer(flex: 1),
          Image.asset(
            'images/djungelskog.jpg',
            height: 200,
            width: 200,
          ),
          const Spacer(flex: 2),
          const Text("Are you in the mood?", style: TextStyle(fontSize: 24)),
          Switch(
              value: isSwitch,
              onChanged: (bool newBool) {
                setState(() {
                  isSwitch = newBool;
                });
              }),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
