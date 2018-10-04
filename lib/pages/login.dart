import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../github/pullrequest.dart';
import '../github/graphql.dart' as graphql;
import '../github/user.dart';
import '../github/issue.dart';

import '../pages/prlistview.dart';
import '../pages/issuelistview.dart';

class LoginPage extends StatefulWidget {
  @override
    State<StatefulWidget> createState() {
      return _LoginPageState();
    }
}

class _LoginPageState extends State<LoginPage> {
  String _emailValue;
  String _passwordValue;

  Widget _buildEmailTextField() {
    return TextField(
        decoration: InputDecoration(
            labelText: 'E-Mail', filled: true, fillColor: Colors.white),
        keyboardType: TextInputType.emailAddress,
        onChanged: (String value) {
          setState(() {
            _emailValue = value;
          });
        });
  }

  Widget _buildPasswordTextField() {
    return TextField(
        obscureText: true,
        decoration: InputDecoration(
            labelText: 'Password', filled: true, fillColor: Colors.white),
        onChanged: (String value) {
          setState(() {
            _passwordValue = value;
          });
        });
  }

  _sendLoginCreds() {
    print(_emailValue);
    print(_passwordValue);
    // send graphQL login mutation query
    graphql.loginAuth(_emailValue, _passwordValue);
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double targetWidth = deviceWidth  > 768.0 ? 500.0 : deviceWidth * 0.95;

    return Scaffold(
      appBar: AppBar(
        title: Text('DX-Mobile'),
      ),
      body: Container(
          padding: EdgeInsets.all(10.0),
          child: Center(
              child: SingleChildScrollView(
                  child: Container(
                    width: targetWidth,
                      child: Column(
            children: <Widget>[
              Text('Log in with GitHub'),
              _buildEmailTextField(),
              SizedBox(height: 10.0),
              _buildPasswordTextField(),
              SizedBox(height: 10.0),
              RaisedButton(
                child: Text('LOGIN'),
                color: Theme.of(context).primaryColor,
                onPressed: _sendLoginCreds,
              ),
            ],
          ))))),
    );
  }


}