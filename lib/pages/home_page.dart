import 'dart:async';
import 'dart:math';
import 'dart:ui' as prefix0;
import 'package:flutter/material.dart';
import 'package:flutter_gas/network/get_image.dart';
import 'package:flutter_gas/network/get_one_sentence.dart';
import 'package:flutter_gas/pages/config_page.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:convert';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String imageUrl = "";
  String sentence = "";
  String author = "";
  int co2 = 0;
  int hum = 0;
  int tem = 0;

  String broker = "35.185.152.124";
  String userName = "ctl";
  String passWord = "997103";
  String clientIdentifier = Random(1).toString();

  MqttClient client;
  MqttClientConnectionStatus clientConnectionStatus;
  StreamSubscription subscription;

  void _connect() async {
    client = MqttClient(broker, '');
    client.port = 1883;
    client.keepAlivePeriod = 30;
    client.onDisconnected = _onDisconnected;

    final MqttConnectMessage connectMessage = MqttConnectMessage()
      .withClientIdentifier(clientIdentifier)
    .startClean()
    .keepAliveFor(30)
    .withWillQos(MqttQos.atMostOnce);
    client.connectionMessage = connectMessage;

    try {
      await client.connect(userName, passWord);
    } catch (e) {
      print(e);
      _disconnect();
    }

    if (client.connectionStatus.state == MqttConnectionState.connected) {
      print('EXAMPLE::Mosquitto client connected');
    } else {
      /// Use status here rather than state if you also want the broker return code.
      print(
          'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
    }
    subscription = client.updates.listen(_onMessage);
//    TODO: 订阅
    const String topic = 'classroomSensorData'; // Not a wildcard topic
    client.subscribe(topic, MqttQos.atMostOnce);
    client.subscribe("classroomSensor/available", MqttQos.atMostOnce);
  }

  void _disconnect() {
    print('[MQTT client] _disconnect()');
    client.disconnect();
    _onDisconnected();
    _connect();
  }

  void _onDisconnected() {
    print('[MQTT client] _onDisconnected');
    setState(() {
      //topics.clear();
      client = null;
      subscription.cancel();
      subscription = null;
    });
    print('[MQTT client] MQTT client disconnected');
  }

  void _onMessage(List<MqttReceivedMessage> event) {
    print(event.length);
    final MqttPublishMessage recMess =
    event[0].payload as MqttPublishMessage;
    final String message =
    MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    /// The above may seem a little convoluted for users only interested in the
    /// payload, some users however may be interested in the received publish message,
    /// lets not constrain ourselves yet until the package has been in the wild
    /// for a while.
    /// The payload is a byte buffer, this will be specific to the topic
//    print('[MQTT client] MQTT message: topic is <${event[0].topic}>, '
//        'payload is <-- ${message} -->');
//    print("[MQTT client] message with topic: ${event[0].topic}");
//    print("[MQTT client] message with message: ${message}");
    if (event[0].topic == "classroomSensorData") {
      print(message.runtimeType);
      Map<String, dynamic> jsonMap = json.decode(message);
      setState(() {
        co2 = jsonMap["co2"];
        hum = jsonMap["hum"];
        tem = jsonMap["tem"];
      });
  }

  }

  @override
  void initState() {
    super.initState();
    RequestImage().getImage().then((value) {
      setState(() {
        imageUrl = value;
      });
    });
    GetSentence().getSentence().then((value) {
      print(value);
      setState(() {
        sentence = value["sentence"];
        author = value["author"];
      });
    });
    _connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    ClipPath(
                        clipper: BottonClipper(),
                        child: Stack(
                          children: <Widget>[
                            bgImage(),
                            appBar(context),
                            showSentence(),
                          ],
                        )),
                    Padding(padding: EdgeInsets.symmetric(vertical: 20)),
                    showContent()
                  ],
                ),
              ],
            )));
  }

  Widget bgImage() {
    return Container(
      color: Colors.blue,
      height: 400,
      child: imageUrl != ""
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
            )
          : Image.asset(
              "images/th.jpg",
              fit: BoxFit.cover,
            ),
    );
  }

  Widget appBar(BuildContext context) {
    return SafeArea(
        child: Container(
            height: MediaQuery.of(context).padding.top * 3,
            width: prefix0.window.physicalSize.width,
            child: Container(
              alignment: Alignment.bottomRight,
              child: IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) => ConfigPage()));
                  }),
            )));
  }

  Widget showSentence() {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: 150),
          alignment: Alignment.center,
          child: Center(
            child: Text(
              sentence,
              style: TextStyle(
                  fontSize: 30, fontFamily: 'Bubian', color: Colors.white),
            ),
          ),
        ),
        Text(
          author,
          style: TextStyle(
              fontSize: 20, fontFamily: 'Bubian', color: Colors.white),
        ),
      ],
    );
  }

  Widget showContent() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            customItem("images/co2.png", Colors.green, 40, 5, 10, "$co2", 20,
                Colors.grey, "二氧化碳", 15, Colors.grey),
            Padding(padding: EdgeInsets.symmetric(horizontal: 40)),
            customItem("images/温度.png", Colors.orange, 40, 5, 10, "$tem℃", 20,
                Colors.grey, "温度", 15, Colors.grey),
            Padding(padding: EdgeInsets.symmetric(horizontal: 40)),
            customItem("images/湿度.png", Colors.blue, 40, 5, 10, "$hum%Rh", 20,
                Colors.grey, "湿度", 15, Colors.grey)
          ]),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Container(
              width: 350,
              height: 3.0,
              color: Color(0xFFF3F3F3),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            customItem("images/co2.png", Colors.green, 40, 5, 10, "10 ppm", 20,
                Colors.grey, "二氧化碳", 15, Colors.grey),
            Padding(padding: EdgeInsets.symmetric(horizontal: 40)),
            customItem("images/温度.png", Colors.orange, 40, 5, 10, "10 ℃", 20,
                Colors.grey, "温度", 15, Colors.grey),
            Padding(padding: EdgeInsets.symmetric(horizontal: 40)),
            customItem("images/湿度.png", Colors.blue, 40, 5, 10, "10 %Rh", 20,
                Colors.grey, "湿度", 15, Colors.grey)
          ]),
        ],
      ),
    );
  }

  Widget customItem(
      String assetUrl,
      Color iconColor,
      double iconSize,
      double vPadding,
      double hPadding,
      String sensorData,
      double sensorDataSize,
      Color sensorDataColor,
      String hint,
      double hintSize,
      Color hintColor) {
    return Column(
      children: <Widget>[
        Image.asset(
          assetUrl,
          width: iconSize,
          color: iconColor,
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: vPadding)),
        Text(
          sensorData,
          style: TextStyle(fontSize: sensorDataSize, color: sensorDataColor),
        ),
        Padding(
            padding:
                EdgeInsets.symmetric(vertical: vPadding, horizontal: hPadding)),
        Text(hint, style: TextStyle(fontSize: hintSize, color: hintColor))
      ],
    );
  }


}


class BottonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // 路径
    var path = Path();
    // 设置路径的开始点
    path.lineTo(0, 0);
    path.lineTo(0, size.height - 50);

    // 设置第一个曲线的样式
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPont = Offset(size.width / 2, size.height - 40);

    // 把设置好的第一个样式添加到路径里面
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPont.dx, firstEndPont.dy);

    // 设置第二个曲线的样式
    var secondConttrolPoint = Offset(size.width / 4 * 3, size.height - 70);
    var secondEndpoint = Offset(size.width, size.height - 40);

    // 把第二个设置好的样式添加到路径里面
    path.quadraticBezierTo(secondConttrolPoint.dx, secondConttrolPoint.dy,
        secondEndpoint.dx, secondEndpoint.dy);
    // 设置路径的结束点
    path.lineTo(size.width, size.height - 40);
    path.lineTo(size.width, 0);

    // 返回路径
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
