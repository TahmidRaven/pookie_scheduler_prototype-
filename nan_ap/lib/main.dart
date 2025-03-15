import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const PookieSchedulerApp());
}

class PookieSchedulerApp extends StatelessWidget {
  const PookieSchedulerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pookie Scheduler',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const SchedulePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  bool _isRamadanTiming = false;
  late Timer _timer;
  String _remainingTime = "";
  
  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
  }
  
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  
  void _updateRemainingTime() {
    final now = DateTime.now();
    
    // Find the next class
    final schedule = getFullSchedule();
    DateTime? nextClassTime;
    String? nextClassName;
    
    for (var entry in schedule.entries) {
      final day = entry.key;
      final classes = entry.value;
      
      if (day == _getDayName(now.weekday)) {
        for (var classInfo in classes) {
          final classDateTime = _parseClassTime(now, classInfo['time']!);
          if (classDateTime.isAfter(now)) {
            if (nextClassTime == null || classDateTime.isBefore(nextClassTime)) {
              nextClassTime = classDateTime;
              nextClassName = classInfo['course'];
            }
          }
        }
      }
    }
    
    // If no class today, check tomorrow
    if (nextClassTime == null) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowDayName = _getDayName(tomorrow.weekday);
      
      if (schedule.containsKey(tomorrowDayName)) {
        final classes = schedule[tomorrowDayName]!;
        if (classes.isNotEmpty) {
          nextClassTime = _parseClassTime(tomorrow, classes.first['time']!);
          nextClassName = classes.first['course'];
        }
      }
    }
    
    if (nextClassTime != null && nextClassName != null) {
      final difference = nextClassTime.difference(now);
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      final seconds = difference.inSeconds % 60;
      
      setState(() {
        _remainingTime = 'Next: $nextClassName in ${hours}h ${minutes}m ${seconds}s';
      });
    } else {
      setState(() {
        _remainingTime = 'No upcoming classes';
      });
    }
  }
  
  DateTime _parseClassTime(DateTime date, String timeString) {
    final timeParts = timeString.split(' - ')[0].split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1].split(' ')[0]);
    final isPM = timeString.contains('PM') && hour != 12;
    
    if (isPM) {
      hour += 12;
    }
    
    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }
  
  String _getDayName(int weekday) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
  
  Map<String, List<Map<String, String>>> getFullSchedule() {
    final regularSlots = [
      "08:00 AM - 09:20 AM",
      "09:30 AM - 10:50 AM",
      "11:00 AM - 12:20 PM",
      "12:30 PM - 01:50 PM",
      "02:00 PM - 03:20 PM",
      "03:30 PM - 04:50 PM",
      "05:00 PM - 06:20 PM",
    ];
    
    final ramadanSlots = [
      "08:00 AM - 09:05 AM",
      "09:15 AM - 10:20 AM",
      "10:30 AM - 11:35 AM",
      "11:45 AM - 12:50 PM",
      "01:00 PM - 02:05 PM",
      "02:15 PM - 03:20 PM",
      "03:30 PM - 04:35 PM",
    ];
    
    final slots = _isRamadanTiming ? ramadanSlots : regularSlots;
    
    return {
      'Sunday': [
        {'course': 'CSE360', 'room': '10B-15C', 'time': slots[2]},
        {'course': 'CSE340', 'room': '09D-18C', 'time': slots[4]},
      ],
      'Monday': [
        {'course': 'POL102', 'room': '09E-23C', 'time': slots[2]},
        {'course': 'CSE321', 'room': '09A-07C', 'time': slots[3]},
      ],
      'Tuesday': [
        {'course': 'CSE360', 'room': '10B-15C', 'time': slots[2]},
        {'course': 'CSE340', 'room': '09D-18C', 'time': slots[4]},
      ],
      'Wednesday': [
        {'course': 'POL102', 'room': '09E-23C', 'time': slots[2]},
        {'course': 'CSE321', 'room': '09A-07C', 'time': slots[3]},
      ],
      'Saturday': [
        {'course': 'CSE360 Lab', 'room': '10G-33L', 'time': slots[0]},
        {'course': 'CSE321 Lab', 'room': '12D-26L', 'time': slots[2]},
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final schedule = getFullSchedule();
    final now = DateTime.now();
    final currentDay = _getDayName(now.weekday);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('PookieScheduler'),
        actions: [
          Row(
            children: [
              Text(_isRamadanTiming ? 'Ramadan' : 'Regular'),
              Switch(
                value: _isRamadanTiming,
                onChanged: (value) {
                  setState(() {
                    _isRamadanTiming = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Countdown banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.purple.shade100,
            child: Text(
              _remainingTime,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Day selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                  'Sunday',
                ].map((day) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentDay == day ? const Color.fromARGB(255, 134, 53, 149) : null,
                    ),
                    onPressed: () {
                      // No action needed for this simple version
                    },
                    child: Text(day.substring(0, 3)),
                  ),
                )).toList(),
              ),
            ),
          ),
          
          // Schedule list
          Expanded(
            child: ListView(
              children: [
                for (var day in schedule.keys)
                  ExpansionTile(
                    initiallyExpanded: day == currentDay,
                    title: Text(
                      day,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      for (var classInfo in schedule[day]!)
                        ListTile(
                          title: Text(classInfo['course']!),
                          subtitle: Text('${classInfo['time']} • ${classInfo['room']}'),
                          leading: const Icon(Icons.school),
                        ),
                      if (schedule[day]!.isEmpty)
                        const ListTile(
                          title: Text('No classes'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}