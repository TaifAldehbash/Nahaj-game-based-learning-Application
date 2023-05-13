import 'package:flutter/material.dart';
import 'package:nahaj/Group/GroupInfo.dart';
import 'package:nahaj/NahajClasses/Chats.dart';
import 'package:nahaj/presenter.dart';
import 'package:nahaj/NahajClasses/classes.dart';
import 'package:sizer/sizer.dart';

class Group extends StatefulWidget {
  final Groups group;
  final User user;
  final Presenter db;
  Group({
    Key? key,
    required this.db,
    required this.group,
    required this.user,
  }) : super(key: key);

  @override
  _Group createState() => _Group();
}

class _Group extends State<Group> {
  @override
  Widget build(BuildContext context) => Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Color.fromARGB(255, 224, 224, 224),
        body: SafeArea(
          child: Column(
            children: [
              ProfileHeaderWidget(
                  group: widget.group, db: widget.db, user: widget.user),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(1.0.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: MessagesWidget(
                      group: widget.group, user: widget.user, db: widget.db),
                ),
              ),
              NewMessageWidget(
                  user: widget.user,
                  db: widget.db,
                  groupId: widget.group.groupId)
            ],
          ),
        ),
      );
}

//header
class ProfileHeaderWidget extends StatelessWidget {
  final Groups group;
  final Presenter db;
  final User user;

  const ProfileHeaderWidget({
    required this.group,
    required this.db,
    required this.user,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        height: 14.w,
        padding: EdgeInsets.all(1.6.w).copyWith(left: 0),
        child: Column(
          children: [
            Row(
              //mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: Image(
                    image: AssetImage("assets/PreviosButton.png"),
                    alignment: Alignment.topLeft,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/HomePage', (Route<dynamic> route) => false);
                  },
                ),
                //BackButton(color: Colors.blue[600]),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      group.groupName,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 2.4.w,
                        fontFamily: 'Cairo',
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      height: 9.w,
                      width: 9.h,
                      child: buildIcon(1, AssetImage(''), group.groupImage),
                    ),
                    //group image
                    SizedBox(
                      width: 9.0.h,
                      height: 4.0.h,
                      child: GestureDetector(
                        onTap: () {
                          print("pressed group info");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GroupInfo(
                                    db: db, group: group, user: user)),
                          );
                        },
                        child:
                            buildIcon(0, AssetImage("assets/Group13.png"), ''),
                      ),
                    ),
                  ],
                ),

                SizedBox(width: 4),
              ],
            )
          ],
        ),
      );

  Widget buildIcon(int type, AssetImage assetImage, String image) => Container(
        decoration: type == 1
            ? BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                image: DecorationImage(
                    fit: BoxFit.scaleDown, image: NetworkImage(image)))
            : BoxDecoration(),
        child: type == 1
            ? Container()
            : Image(
                image: AssetImage("assets/Group13.png"),
              ),
      );
}

//read messages form db
class MessagesWidget extends StatelessWidget {
  final Groups group;
  final User user;
  final Presenter db;
  //final Groups group;

  const MessagesWidget({
    required this.group,
    required this.user,
    required this.db,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Chat>>(
        stream: db.getMessagesList(group.groupId),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());
            default:
              if (snapshot.hasError) {
                return buildText(
                    'Something Went Wrong Try later ${snapshot.hasError}');
              } else {
                final allMessages = snapshot.data;
                return allMessages == null
                    ? buildText('Say Hi..')
                    : ListView.builder(
                        physics: BouncingScrollPhysics(),
                        reverse: true,
                        itemCount: allMessages.length,
                        itemBuilder: (context, index) {
                          final message = allMessages[index]; //[index];

                          return MessageWidget(
                            message: message,
                            userName: message.username,
                            isMe: message.userId == user.userId,
                          );
                        },
                      );
              }
          }
        },
      );

  Widget buildText(String text) => Center(
        child: Text(
          text,
          style: TextStyle(fontSize: 2.4.w),
        ),
      );
}

//send message tstyle
class NewMessageWidget extends StatefulWidget {
  final User user;
  final Presenter db;
  final String groupId;

  const NewMessageWidget({
    required this.user,
    required this.db,
    required this.groupId,
    Key? key,
  }) : super(key: key);

  @override
  _NewMessageWidgetState createState() => _NewMessageWidgetState();
}

class _NewMessageWidgetState extends State<NewMessageWidget> {
  final _controller = TextEditingController();
  String message = '';

  void sendMessage() async {
    // down the keyboard
    FocusScope.of(context).unfocus();

    await widget.db
        .uploadMessage(
            widget.groupId, widget.user.userId, widget.user.username, message)
        .then((value) => print("added success"));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: EdgeInsets.all(.8.h),
        child: Row(
          children: <Widget>[
            //text field
            Expanded(
              child: TextField(
                controller: _controller,
                textDirection: TextDirection.rtl,
                textCapitalization: TextCapitalization.sentences,
                autocorrect: true,
                enableSuggestions: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  hintTextDirection: TextDirection.rtl,
                  hintText: 'اكتب رسالتك..',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(width: 0),
                    gapPadding: 1.0.h,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onChanged: (value) => setState(() {
                  message = value;
                }),
              ),
            ),
            //space
            SizedBox(width: 2.0.h),
            //send icon
            GestureDetector(
              onTap: message.trim().isEmpty ? null : sendMessage,
              child: Container(
                padding: EdgeInsets.all(1.5.h),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      );
}

//Styling of chat body
class MessageWidget extends StatelessWidget {
  final String userName;
  final Chat message;
  final bool isMe;

  const MessageWidget({
    required this.message,
    required this.userName,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(12);
    final borderRadius = BorderRadius.all(radius);

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: <Widget>[
        Column(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Container(
                padding: EdgeInsets.only(top: 1.6.w),
                margin: EdgeInsets.only(top: 1.6.w, left: 1.6.h),
                child: Text(userName,
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      fontSize: 2.w,
                    ),
                    textAlign: TextAlign.start,
                    textDirection: TextDirection.rtl),
              ),
            Container(
              padding: isMe
                  ? EdgeInsets.only(
                      top: 1.6.w, bottom: 1.6.w, left: 3.6.h, right: 1.6.h)
                  : EdgeInsets.only(bottom: 1.6.w, left: 1.6.h, right: 3.6.h),
              margin: isMe
                  ? EdgeInsets.all(16)
                  : EdgeInsets.only(bottom: 16, left: 16, right: 16),
              constraints: BoxConstraints(maxWidth: 40.h),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: isMe ? Colors.grey[100] : Theme.of(context).accentColor,
                borderRadius: isMe
                    ? borderRadius
                        .subtract(BorderRadius.only(bottomRight: radius))
                    : borderRadius
                        .subtract(BorderRadius.only(bottomLeft: radius)),
              ),
              child: buildMessage(),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildMessage() => Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          Text(
            message.message,
            style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                color: isMe ? Colors.black : Colors.white),
            textAlign: isMe ? TextAlign.end : TextAlign.start,
          ),
        ],
      );
}
