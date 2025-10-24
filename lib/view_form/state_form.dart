import 'package:flutter/material.dart';
import 'package:to_do_list/model/task_state.dart';

class StateForm extends StatefulWidget {
  final Function(TaskState)? createTState;
  final Function(TaskState)? editTState;

  final TaskState state;

  const StateForm({super.key, this.createTState, this.editTState, required this.state});

  @override
  StateFormState createState() => StateFormState();
}

class StateFormState extends State<StateForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  String validator = '';

  late String colorSelected;

  late bool isCreating;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.state.name);
    isCreating = widget.createTState != null;
    colorSelected = isCreating ? 'blue' : TaskState.colorName(widget.state.color);
  }

  @override
  Widget build(BuildContext context) {
    TaskState tState = TaskState.copy(widget.state);

    String name = tState.name;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 5),
              child: TextFormField(
                decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Nom'),
                controller: nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Aquest camp és obligatori';
                  }
                  return null;
                },
                onSaved: (value) {
                  name = value!;
                },
              ),
            ),

            SizedBox(height: 10),

            Row(
              children: [
                Container(width: 5),

                Text('Color', style: TextStyle(fontSize: 16)),

                Container(width: 10),

                DropdownButton<String>(
                  underline: const SizedBox(),
                  //borderRadius: BorderRadius.circular(10),
                  padding: const EdgeInsets.symmetric(horizontal: 10),

                  /*hint: Row(
                    children: [
                      Container(width: 24, height: 24, color: TaskState.colorMap['blue']),
                      //const SizedBox(width: 8),
                      //Text('blue'),
                    ],
                  ),*/
                  value: colorSelected,
                  items: TaskState.colorMap.keys.map((String colorName) {
                    return DropdownMenuItem<String>(
                      value: colorName,
                      child: Container(width: 30, height: 30, color: TaskState.colorMap[colorName]),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue == null) {
                      colorSelected = 'null';
                    } else {
                      colorSelected = newValue;
                    }
                    setState(() {});
                  },
                  selectedItemBuilder: (BuildContext context) {
                    return TaskState.colorMap.keys.map((String colorName) {
                      return Center(child: Container(width: 30, height: 30, color: TaskState.colorMap[colorName]));
                    }).toList();
                  },
                  menuMaxHeight: 300,
                ),
              ],
            ),

            SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  Color? color;

                  if (colorSelected == 'null') {
                    color = null;
                  } else {
                    color = TaskState.colorValue(colorSelected);
                  }

                  TaskState updatedState = widget.state.copyWith(
                    name: name,
                    //color: TaskState.colorValue(colorSelected),
                    color: color,
                    setColor: true,
                  );

                  if (isCreating) {
                    widget.createTState!(updatedState);
                  } else if (widget.editTState != null) {
                    widget.editTState!(updatedState);
                  }

                  //Navigator.of(context).pop();
                }
              },
              icon: Icon(isCreating ? Icons.add : Icons.save_alt),
              label: Text(isCreating ? 'Crear' : 'Guardar canvis'),

              //icon: Icon(Icons.abc),
              //label: Text(!isNew ? 'Guardar canvis' : 'Crear estat'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
  }
}
