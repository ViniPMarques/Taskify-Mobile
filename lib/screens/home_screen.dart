import 'package:flutter/material.dart';
import 'dart:io' as io;
import '../services/notification_service.dart';
import 'add_task_screen.dart';
import '../main.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'package:image_picker/image_picker.dart';

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

  void _deleteImage(Task task) async {
    task.imagePath = null;
    await TaskService.instance.updateTask(task);
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
                    decoration: InputDecoration(labelText: 'Título'),
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
                              selectedTime = null;
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
                          child: Text(selectedDate != null ? "${selectedDate?.toLocal()}".split(' ')[0] : "Selecione uma data"),
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
                              initialTime: selectedTime ?? TimeOfDay(hour: 0, minute: 0),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },
                          child: Text(selectedTime != null ? "${selectedTime?.format(context)}" : "Selecione um horário"),
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
                      imagePath: task.imagePath,
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


  Future<void> _addImage(Task task) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      task.imagePath = pickedFile.path;
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
      body: Padding(
        padding: const EdgeInsets.only(bottom: 60.0),
        child: ListView.builder(
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
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Image.file(io.File(task.imagePath!)),
                      ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (String result) {
                    switch (result) {
                      case 'edit':
                        _editTask(task);
                        break;
                      case 'duplicate':
                        _duplicateTask(task);
                        break;
                      case 'delete':
                        _deleteTask(task.id!);
                        break;
                      case 'add_image':
                        _addImage(task);
                        break;
                      case 'delete_image':
                        _deleteImage(task);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Editar'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'duplicate',
                      child: Text('Duplicar'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Excluir'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'add_image',
                      child: Text('Adicionar Imagem'),
                    ),
                    if (task.imagePath != null)
                      const PopupMenuItem<String>(
                        value: 'delete_image',
                        child: Text('Remover Imagem'),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: FloatingActionButton(
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
