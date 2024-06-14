import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../main.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Map<DateTime, List<Task>> _tasksByDate;
  late List<Task> _selectedTasks;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _tasksByDate = {};
    _selectedTasks = [];
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadTasks();
  }

  void _loadTasks() async {
    List<Task> tasks = await TaskService.instance.fetchTasks();
    Map<DateTime, List<Task>> taskMap = {};
    for (var task in tasks) {
      if (task.dueDate != null) {
        if (!taskMap.containsKey(task.dueDate)) {
          taskMap[task.dueDate!] = [];
        }
        taskMap[task.dueDate!]!.add(task);
      }
    }
    setState(() {
      _tasksByDate = taskMap;
      _selectedTasks = _tasksByDate[_selectedDay] ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Calendar'),
      ),
      drawer: HomeDrawer(),
      body: Column(
        children: [
          TableCalendar<Task>(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2101, 1, 1),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            eventLoader: (day) {
              return _tasksByDate[day] ?? [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedTasks = _tasksByDate[selectedDay] ?? [];
              });
            },
            calendarFormat: CalendarFormat.month,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedTasks.length,
              itemBuilder: (context, index) {
                final task = _selectedTasks[index];
                return ListTile(
                  title: Text(task.title),
                  subtitle: Text(task.description ?? ''),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
