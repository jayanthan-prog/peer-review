import 'package:flutter/material.dart';

// Authentication Provider Class
class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;

  // Getter for isAuthenticated
  bool get isAuthenticated => _isAuthenticated;

  // Function to log in
  void login() {
    _isAuthenticated = true;
    notifyListeners(); // Notify listeners when state changes
  }

  // Function to log out
  void logout() {
    _isAuthenticated = false;
    notifyListeners(); // Notify listeners when state changes
  }
}

// Auth Context: Wrapper for the app to provide AuthProvider
class AuthContext extends InheritedWidget {
  final AuthProvider authProvider;

  AuthContext({Key? key, required Widget child, required this.authProvider})
      : super(key: key, child: child);

  // Access AuthProvider from anywhere in the widget tree
  static AuthProvider of(BuildContext context) {
    final AuthContext? result =
        context.dependOnInheritedWidgetOfExactType<AuthContext>();
    return result!.authProvider;
  }

  @override
  bool updateShouldNotify(AuthContext oldWidget) {
    return oldWidget.authProvider != authProvider;
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuthContext(
      authProvider: AuthProvider(),
      child: MaterialApp(
        home: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = AuthContext.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Auth Context in Flutter')),
      body: Center(
        child: authProvider.isAuthenticated
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('You are logged in!'),
                  ElevatedButton(
                    onPressed: () {
                      authProvider.logout();
                    },
                    child: Text('Log Out'),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('You are not logged in!'),
                  ElevatedButton(
                    onPressed: () {
                      authProvider.login();
                    },
                    child: Text('Log In'),
                  ),
                ],
              ),
      ),
    );
  }
}
