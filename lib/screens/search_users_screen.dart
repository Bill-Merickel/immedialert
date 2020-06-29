import 'package:emergencycommunication/models/group_data.dart';
import 'package:emergencycommunication/models/user_data.dart';
import 'package:emergencycommunication/models/user_model.dart';
import 'package:emergencycommunication/screens/create_chat_screen.dart';
import 'package:emergencycommunication/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

class SearchUsersScreen extends StatefulWidget {
  @override
  _SearchUsersScreenState createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];
  List<User> _selectedUsers = [];

  _clearSearch() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _searchController.clear());
    setState(() => _users = []);
  }

  _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) {
        return PlatformAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            PlatformDialogAction(
              child: Text('Ok'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Provider.of<UserData>(context, listen: false).currentUserId;
    final currentGroupId =
        Provider.of<GroupData>(context, listen: false).currentGroupId;
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        brightness: Brightness.dark,
        title: Text(
          'Search Users',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              if (_selectedUsers.length > 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateChatScreen(
                      selectedUsers: _selectedUsers,
                    ),
                  ),
                );
              } else {
                _showAlertDialog('No Users Selected',
                    'Select one or more users to create a new chat.');
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _searchController,
              cursorColor: Theme.of(context).primaryColor,
              style: TextStyle(
                fontFamily: 'Montserrat',
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                border: InputBorder.none,
                hintText: 'Search',
                hintStyle: TextStyle(
                  fontFamily: 'Montserrat',
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 30.0,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: _clearSearch,
                ),
                filled: true,
              ),
              onSubmitted: (input) async {
                if (input.trim().isNotEmpty) {
                  List<User> users =
                      await Provider.of<DatabaseService>(context, listen: false)
                          .searchUsers(currentUserId, currentGroupId, input);

                  List<User> usersToRemove = [];
                  for (var selectedUser in _selectedUsers) {
                    for (var user in users) {
                      if (selectedUser.id == user.id) {
                        usersToRemove.add(user);
                      }
                    }
                  }

                  users.removeWhere((user) => usersToRemove.contains(user));
                  setState(() => _users = users);
                }
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _selectedUsers.length + _users.length,
                itemBuilder: (BuildContext context, int index) {
                  if (index < _selectedUsers.length) {
                    // Display selected users
                    User selectedUser = _selectedUsers[index];
                    return ListTile(
                      title: Text(
                        selectedUser.name,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Icon(Icons.check_circle),
                      onTap: () {
                        _selectedUsers.remove(selectedUser);
                        _users.insert(0, selectedUser);
                        setState(() {});
                      },
                    );
                  }
                  int userIndex = index - _selectedUsers.length;
                  User user = _users[userIndex];

                  return ListTile(
                    title: Text(
                      user.name,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    trailing: Icon(Icons.check_circle_outline),
                    onTap: () {
                      _selectedUsers.add(user);
                      _users.remove(user);
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
