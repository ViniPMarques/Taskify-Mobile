import 'package:flutter/material.dart';
import 'add_task_screen.dart';
import '../main.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() async {
    List<Task> tasks = await TaskService.instance.fetchTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  void _deleteTask(int id) async {
    await TaskService.instance.deleteTask(id);
    _loadTasks();
  }

  void _duplicateTask(Task task) async {
    Task newTask = Task(
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      dueTime: task.dueTime,
    );
    await TaskService.instance.addTask(newTask);
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Taskify'),
      ),
      drawer: HomeDrawer(),
      body: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return ListTile(
            title: Text(task.title),
            subtitle: Text(task.description ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () {
                    _duplicateTask(task);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _deleteTask(task.id!);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen()),
          ).then((value) {
            if (value != null) {
              _loadTasks();
            }
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
