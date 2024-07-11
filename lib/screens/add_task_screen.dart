import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/notification_service.dart';

class AddTaskScreen extends StatefulWidget {
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _hasDueDate = true;

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      DateTime? scheduledDate;
      if (_hasDueDate && _dueDate != null && _dueTime != null) {
        scheduledDate = DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          _dueTime!.hour,
          _dueTime!.minute,
        );
      }

      Task newTask = Task(
        title: _title,
        description: _description,
        dueDate: _hasDueDate ? _dueDate : null,
        dueTime: _hasDueDate ? _dueTime : null,
      );
      await TaskService.instance.addTask(newTask);

      if (scheduledDate != null) {
        NotificationService().scheduleNotification(
          newTask.id ?? 0,
          'Tarefa Pendente: $_title',
          _description,
          scheduledDate,
        );
      }

      Navigator.pop(context, newTask);
    }
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _dueTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Tarefa'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Título'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor insira o título da tarefa';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _title = value;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Descrição'),
                onChanged: (value) {
                  setState(() {
                    _description = value;
                  });
                },
              ),
              CheckboxListTile(
                title: Text("Ativar data de vencimento"),
                value: _hasDueDate,
                onChanged: (bool? value) {
                  setState(() {
                    _hasDueDate = value!;
                  });
                },
              ),
              if (_hasDueDate) ...[
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text('Selecionar data'),
                ),
                ElevatedButton(
                  onPressed: () => _selectTime(context),
                  child: Text('Selecionar hora'),
                ),
                SizedBox(height: 20),
                Text(
                  _dueDate != null
                      ? 'Data Vencimento: ${DateFormat.yMd().format(_dueDate!)}'
                      : 'Nenhuma data definida',
                ),
                Text(
                  _dueTime != null
                      ? 'Hora Vencimento: ${_dueTime!.format(context)}'
                      : 'Nenhum horário definido',
                ),
              ],
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveTask,
                child: Text('Salvar Tarefa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
