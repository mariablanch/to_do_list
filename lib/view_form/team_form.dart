import 'package:flutter/material.dart';
import 'package:to_do_list/model/team.dart';
import 'package:to_do_list/model/user.dart';

class TeamForm extends StatefulWidget {
  final Function(Team, List<User>)? onTeamCreated;
  final Function(Team)? onTeamEdited;
  final Team team;
  final List<User> allUsers;
  const TeamForm({super.key, this.onTeamCreated, this.onTeamEdited, required this.team, required this.allUsers});

  @override
  TeamFormState createState() => TeamFormState();
}

class TeamFormState extends State<TeamForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;

  late bool isAdmin = false;

  List<User> users = [];
  Set<String> selectedUserIds = {};
  List<User> selectedUsers = [];

  bool isCreating = false;
  String validator = '';

  late Team team;

  @override
  void initState() {
    super.initState();
    if (widget.onTeamCreated != null) {
      isCreating = true;
    }
    team = Team.copy(widget.team);
    nameController = TextEditingController(text: team.name);
  }

  @override
  Widget build(BuildContext context) {
    String name = team.name;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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

            SizedBox(height: 15),
            if (isCreating) Text('Afegir usuaris:', style: TextStyle(fontWeight: FontWeight.bold),),
            if (isCreating)
              Autocomplete<User>(
                displayStringForOption: (user) => user.userName,

                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return const Iterable<User>.empty();
                  return widget.allUsers.where(
                    (u) =>
                        u.userName.toLowerCase().contains(textEditingValue.text.toLowerCase()) &&
                        !selectedUsers.contains(u),
                  );
                },

                onSelected: (User selection) {
                  setState(() {
                    selectedUsers.add(selection);
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,

                    decoration: InputDecoration(
                      //labelText: 'Nom equip',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                  );
                },
              ),
            if (isCreating) SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: selectedUsers
                  .map(
                    (u) => Chip(
                      label: Text(u.userName),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer.withAlpha(90),
                      side: BorderSide(color: Theme.of(context).colorScheme.inversePrimary),

                      onDeleted: () {
                        setState(() {
                          selectedUsers.remove(u);
                        });
                      },
                      deleteButtonTooltipMessage: 'Eliminar',
                    ),
                  )
                  .toList(),
            ),

            SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  Team updatedTeam = widget.team.copyWith(name: name);

                  if (isCreating) {
                    widget.onTeamCreated!(updatedTeam.copyWith(id: ''), selectedUsers);
                  } else if (widget.onTeamEdited != null) {
                    widget.onTeamEdited!(updatedTeam);
                  }
                }
              },
              icon: Icon(isCreating ? Icons.add : Icons.save_alt),
              label: Text(isCreating ? 'Crear' : 'Guardar canvis'),
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
