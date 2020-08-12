import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification/received_notification.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
NotificationAppLaunchDetails notificationAppLaunchDetails;

// Streams are created so that app can respond to notification-related events since the plugin is initialised in the `main` function
final StreamController<ReceivedNotification>
    didReceiveLocalNotificationSubject =
    StreamController<ReceivedNotification>();

final StreamController<String> selectNotificationSubject =
    StreamController<String>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  var initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');
  // Note: permissions aren't requested here just to demonstrate that can be done later using the `requestPermissions()` method
  // of the `IOSFlutterLocalNotificationsPlugin` class
  var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification:
          (int id, String title, String body, String payload) async {
        didReceiveLocalNotificationSubject.add(ReceivedNotification(
            id: id, title: title, body: body, payload: payload));
      });
  var initializationSettings = InitializationSettings(
      initializationSettingsAndroid, initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }
    selectNotificationSubject.add(payload);
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  String notificationMsg;

  String token;

  @override
  initState() {
    super.initState();
    initFirebase();
    _configureDidReceiveLocalNotificationSubject();
    _configureSelectNotificationSubject();
  }
  void _configureDidReceiveLocalNotificationSubject() {
    didReceiveLocalNotificationSubject.stream
        .listen((ReceivedNotification receivedNotification) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: receivedNotification.title != null
              ? Text(receivedNotification.title)
              : null,
          content: receivedNotification.body != null
              ? Text(receivedNotification.body)
              : null,
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Ok'),
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                print('-----CupertinoDialogAction-----');
              },
            )
          ],
        ),
      );
    });
  }

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String payload) async {
      print('_configureSelectNotificationSubject');

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: getToken,
        child: Icon(Icons.refresh),
      ),
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView(

          children: <Widget>[
            Text(
              'token:$token',
            ),
            Text(
              '$notificationMsg',
              style: Theme.of(context).textTheme.display1,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
              child: Text(
                  'Tap on a notification when it appears to trigger navigation'),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Did notification launch app? ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                      '${notificationAppLaunchDetails?.didNotificationLaunchApp ?? false}',
                    )
                  ],
                ),
              ),
            ),
            if (notificationAppLaunchDetails?.didNotificationLaunchApp ??
                false)
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Launch notification payload: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: notificationAppLaunchDetails.payload,
                      )
                    ],
                  ),
                ),
              ),
            PaddedRaisedButton(
              buttonText: 'Show plain notification with payload',
              onPressed: () async {
                await _showNotification();
              },
            ),
            PaddedRaisedButton(
              buttonText:
              'Show plain notification that has no body with payload',
              onPressed: () async {
                await _showNotificationWithNoBody();
              },
            ),
            PaddedRaisedButton(
              buttonText:
              'Show plain notification with payload and update channel description [Android]',
              onPressed: () async {
                await _showNotificationWithUpdatedChannelDescription();
              },
            ),
            PaddedRaisedButton(
              buttonText:
              'Show plain notification as public on every lockscreen [Android]',
              onPressed: () async {
                await _showPublicNotification();
              },
            ),

            Text(
                'NOTE: red colour, large icon and red LED are Android-specific'),

            PaddedRaisedButton(
              buttonText:
              'Repeat notification weekly on Monday at approximately 10:00:00 am',
              onPressed: () async {
                await _showWeeklyAtDayAndTime();
              },
            ),

            PaddedRaisedButton(
              buttonText:
              'Show progress notification - updates every second [Android]',
              onPressed: () async {
                await _showProgressNotification();
              },
            ),

            PaddedRaisedButton(
              buttonText: 'Show notification with icon badge [iOS]',
              onPressed: () async {
                await _showNotificationWithIconBadge();
              },
            ),
            PaddedRaisedButton(
              buttonText: 'Show notification without timestamp [Android]',
              onPressed: () async {
                await _showNotificationWithoutTimestamp();
              },
            ),
            PaddedRaisedButton(
              buttonText:
              'Show notification with custom timestamp [Android]',
              onPressed: () async {
                await _showNotificationWithCustomTimestamp();
              },
            ),

            PaddedRaisedButton(
              buttonText: 'Create notification channel [Android]',
              onPressed: () async {
                await _createNotificationChannel();
              },
            ),
            PaddedRaisedButton(
              buttonText: 'Delete notification channel [Android]',
              onPressed: () async {
                await _deleteNotificationChannel();
              },
            ),
          ],
        ),
      ),
    );
  }

  void initFirebase() {
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        setState(() {
          notificationMsg = "onMessage: $message";
        });
      },
      onBackgroundMessage: myBackgroundMessageHandler,
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        setState(() {
          notificationMsg = "onLaunch: $message";
        });
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        setState(() {
          notificationMsg = "onResume: $message";
        });
      },
    );

    getToken();
  }

  void getToken() async {
    String token = await _firebaseMessaging.getToken();
    print(token);
    setState(() {
      this.token = token;
    });
  }

  static Future<dynamic> myBackgroundMessageHandler(
      Map<String, dynamic> message) {
    if (message.containsKey('data')) {
      // Handle data message
      final dynamic data = message['data'];
    }

    if (message.containsKey('notification')) {
      // Handle notification message
      final dynamic notification = message['notification'];
    }

    print('------myBackgroundMessageHandler');
    // Or do other work.
  }

  Future<void> _showNotificationWithUpdatedChannelDescription() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id',
        'your channel name',
        'your updated channel description',
        importance: Importance.Max,
        priority: Priority.High,
        channelAction: AndroidNotificationChannelAction.Update);
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0,
        'updated notification channel',
        'check settings to see updated channel description',
        platformChannelSpecifics,
        payload: 'item x');
  }

  @override
  void dispose() {
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    super.dispose();
  }

  Future<void> _showNotification() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'plain title', 'plain body', platformChannelSpecifics,
        payload: 'item x');
  }

  Future<void> _showNotificationWithNoBody() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'plain title', null, platformChannelSpecifics,
        payload: 'item x');
  }

  Future<void> _showNotificationWithIconBadge() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'icon badge channel', 'icon badge name', 'icon badge description');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails(badgeNumber: 1);
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'icon badge title', 'icon badge body', platformChannelSpecifics,
        payload: 'item x');
  }
  Future<void> _showPublicNotification() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max,
        priority: Priority.High,
        ticker: 'ticker',
        visibility: NotificationVisibility.Public);
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, 'public notification title',
        'public notification body', platformChannelSpecifics,
        payload: 'item x');
  }



  Future<void> _showNotificationWithoutTimestamp() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, showWhen: false);
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'plain title', 'plain body', platformChannelSpecifics,
        payload: 'item x');
  }

  Future<void> _showNotificationWithCustomTimestamp() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      'your channel description',
      importance: Importance.Max,
      priority: Priority.High,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch - 120 * 1000,
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'plain title', 'plain body', platformChannelSpecifics,
        payload: 'item x');
  }



  Future<void> _createNotificationChannel() async {
    var androidNotificationChannel = AndroidNotificationChannel(
      'your channel id 2',
      'your channel name 2',
      'your channel description 2',
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);

    await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text(
                'Channel with name \"${androidNotificationChannel.name}\" created'),
            actions: [
              FlatButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  Future<void> _deleteNotificationChannel() async {
    const channelId = 'your channel id 2';
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.deleteNotificationChannel(channelId);

    await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('Channel with id \"$channelId\" deleted'),
            actions: [
              FlatButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
  Future<void> _showWeeklyAtDayAndTime() async {
    var time = Time(10, 0, 0);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'show weekly channel id',
        'show weekly channel name',
        'show weekly description');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.showWeeklyAtDayAndTime(
        0,
        'show weekly title',
        'Weekly notification shown on Monday at approximately ${_toTwoDigitString(time.hour)}:${_toTwoDigitString(time.minute)}:${_toTwoDigitString(time.second)}',
        Day.Monday,
        time,
        platformChannelSpecifics);
  }

  Future<void> _showProgressNotification() async {
    var maxProgress = 5;
    for (var i = 0; i <= maxProgress; i++) {
      await Future.delayed(Duration(seconds: 1), () async {
        var androidPlatformChannelSpecifics = AndroidNotificationDetails(
            'progress channel',
            'progress channel',
            'progress channel description',
            channelShowBadge: false,
            importance: Importance.Max,
            priority: Priority.High,
            onlyAlertOnce: true,
            showProgress: true,
            maxProgress: maxProgress,
            progress: i);
        var iOSPlatformChannelSpecifics = IOSNotificationDetails();
        var platformChannelSpecifics = NotificationDetails(
            androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
        await flutterLocalNotificationsPlugin.show(
            0,
            'progress notification title',
            'progress notification body',
            platformChannelSpecifics,
            payload: 'item x');
      });
    }
  }

  String _toTwoDigitString(int value) {
    return value.toString().padLeft(2, '0');
  }
}

class PaddedRaisedButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;

  const PaddedRaisedButton({
    @required this.buttonText,
    @required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
      child: RaisedButton(child: Text(buttonText), onPressed: onPressed),
    );
  }
}