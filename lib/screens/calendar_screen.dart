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
        DateTime taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        if (!taskMap.containsKey(taskDate)) {
          taskMap[taskDate] = [];
        }
        taskMap[taskDate]!.add(task);
      }
    }
    setState(() {
      _tasksByDate = taskMap;
      _selectedTasks = _tasksByDate[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)] ?? [];
    });
  }

  void _deleteTask(int id) async {
    await TaskService.instance.deleteTask(id);
    _loadTasks();
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
              DateTime cleanDay = DateTime(day.year, day.month, day.day);
              return _tasksByDate[cleanDay] ?? [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                DateTime cleanSelectedDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
                _selectedTasks = _tasksByDate[cleanSelectedDay] ?? [];
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
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _deleteTask(task.id!);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
