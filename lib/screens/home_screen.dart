import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/notification_service.dart';
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
    int newTaskId = await TaskService.instance.addTask(newTask);
    if (newTask.dueDate != null && newTask.dueTime != null) {
      DateTime scheduledDateTime = DateTime(
        newTask.dueDate!.year,
        newTask.dueDate!.month,
        newTask.dueDate!.day,
        newTask.dueTime!.hour,
        newTask.dueTime!.minute,
      );
      NotificationService().scheduleNotification(
        newTaskId,
        newTask.title,
        newTask.description ?? '',
        scheduledDateTime,
      );
    }
    _loadTasks();
  }

  void _editTask(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController titleController = TextEditingController(text: task.title);
        TextEditingController descriptionController = TextEditingController(text: task.description);
        DateTime? selectedDate = task.dueDate;
        TimeOfDay? selectedTime = task.dueTime;
        bool hasDueDate = task.dueDate != null;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Editar Tarefa"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Titulo'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: 'Descrição'),
                  ),
                  Row(
                    children: [
                      Text("Definir Data:"),
                      Checkbox(
                        value: hasDueDate,
                        onChanged: (bool? value) {
                          setState(() {
                            hasDueDate = value ?? false;
                            if (!hasDueDate) {
                              selectedDate = null;
                              selectedTime = null;
                            } else {
                              selectedDate = DateTime.now();
                              selectedTime = TimeOfDay.now();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (hasDueDate) ...[
                    Row(
                      children: [
                        Text("Data:"),
                        SizedBox(width: 10),
                        TextButton(
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                          child: Text("${selectedDate!.toLocal()}".split(' ')[0]),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text("Horário:"),
                        SizedBox(width: 10),
                        TextButton(
                          onPressed: () async {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime ?? TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },
                          child: Text("${selectedTime!.format(context)}"),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    Task updatedTask = Task(
                      id: task.id,
                      title: titleController.text,
                      description: descriptionController.text,
                      dueDate: hasDueDate ? selectedDate : null,
                      dueTime: hasDueDate ? selectedTime : null,
                    );
                    await TaskService.instance.updateTask(updatedTask);
                    _loadTasks();
                    Navigator.of(context).pop();
                  },
                  child: Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage(Task task) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      task.imagePath = image.path;
      await TaskService.instance.updateTask(task);
      _loadTasks();
    }
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
          return Container(
            color: index % 2 == 0 ? Colors.white : Colors.grey[200],
            child: ListTile(
              title: Text(task.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.description ?? ''),
                  if (task.dueDate != null)
                    Text("Data Definida: ${task.dueDate!.toLocal().toString().split(' ')[0]}"),
                  if (task.dueTime != null)
                    Text("Horário Definido: ${task.dueTime!.format(context)}"),
                  if (task.imagePath != null)
                    Image.file(File(task.imagePath!)),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (String value) async {
                  if (value == 'Edit') {
                    _editTask(task);
                  } else if (value == 'Duplicate') {
                    _duplicateTask(task);
                  } else if (value == 'Delete') {
                    _deleteTask(task.id!);
                  } else if (value == 'Image') {
                    await _pickImage(task);
                  }
                },
                itemBuilder: (BuildContext context) {
                  return {'Edit', 'Duplicate', 'Delete', 'Image'}.map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(choice),
                    );
                  }).toList();
                },
              ),
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
