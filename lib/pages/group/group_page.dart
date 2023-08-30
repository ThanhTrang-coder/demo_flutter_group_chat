import 'dart:developer';

import 'package:demo_group_chat_app/foundation/msg_widget/other_msg_widget.dart';
import 'package:demo_group_chat_app/foundation/msg_widget/own_msg_widget.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'msg_model.dart';

class GroupPage extends StatefulWidget {
  final String name;
  final String userId;

  GroupPage({
    Key? key,
    required this.name,
    required this.userId
  }) : super(key: key);

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  IO.Socket? socket;
  List <MsgModel>listMsg = [];
  TextEditingController _msgController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boomerang group'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: listMsg.length,
              itemBuilder: (context, index) {
                if(listMsg[index].type == "ownMsg") {
                  return OwnMsgWidget(
                    sender: listMsg[index].sender,
                    msg: listMsg[index].msg,
                  );
                } else {
                  return OtherMsgWidget(
                    sender: listMsg[index].sender,
                    msg: listMsg[index].msg,
                  );
                }
              }
            )
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Type here....',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide(width: 2),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          String msg = _msgController.text;
                          if(msg.length > 0) {
                            sendMsg(msg, widget.name);
                            _msgController.clear();
                          }
                        },
                        icon: const Icon(
                          Icons.send,
                          color: Colors.teal,
                          size: 26,
                        ),
                      ),
                    ),
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void connect() {
    socket = IO.io(
      'https://chat-server-demo.onrender.com/', <String, dynamic>{
        "transports": ['websocket'],
        "autoConnect": false,
    });
    socket!.connect();
    socket!.onConnect((data) => {
      print('connected into frontend'),
      socket!.on('sendMsgServer', (msg) => {
        print(msg),
        if(msg["userId"] != widget.userId) {
          setState(() {
            listMsg.add(
              MsgModel(
                type: msg["type"],
                msg: msg["msg"],
                sender: msg["senderName"]
              )
            );
          })
        },
      }),
    });
    socket!.onDisconnect((data) => print('disconnect:::::: ${data}'));
  }

  void sendMsg(String msg, String senderName) {
    MsgModel ownMsg = MsgModel(type: "ownMsg", msg: msg, sender: senderName);
    listMsg.add(ownMsg);
    setState(() {
      listMsg;
    });
    socket!.emit('sendMsg', {
      "type": "ownMsg",
      "msg": msg,
      "senderName": senderName,
      "userId": widget.userId,
    });
  }
}
