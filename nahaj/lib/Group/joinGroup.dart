import 'package:flutter/material.dart';
import 'package:nahaj/NahajClasses/classes.dart';
import 'package:nahaj/presenter.dart';

class JoinGroup extends StatefulWidget {
  final Presenter db;
  final User user;
  const JoinGroup({Key? key, required this.db, required this.user})
      : super(key: key);

  @override
  _JoinGroup createState() => _JoinGroup();
}

class _JoinGroup extends State<JoinGroup> {
  final _key = GlobalKey<FormState>();

  int groupCode = -1;
  bool validName = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          //Background
          Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/SignUpSignInbackground.png"),
                    fit: BoxFit.cover)),
          ),
          //list view container
          ListView(
            key: _key,
            children: [
              //back button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.white.withOpacity(0),
                  onPrimary: Colors.white.withOpacity(0),
                  //minimumSize: Size(30, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(800.0)),
                  alignment: Alignment.topLeft,
                  elevation: 0.0,
                ),
                child: Image(
                  image: AssetImage("assets/PreviosButton.png"),
                ),
                onPressed: () {
                  setState(() {
                    Navigator.of(context).pop();
                  });
                },
              ),
              //logo
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(
                        width: MediaQuery.of(context).size.width / 1.09,
                        height: MediaQuery.of(context).size.height / 4.18,
                        image: AssetImage("assets/nahajLogo.png"))
                  ],
                ),
              ),
              //انضمام للمجموعه
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.1,
                child: Padding(
                  padding: EdgeInsets.only(top: 0, left: 750),
                  child: Text(
                    ": رمز المجموعة ",
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      fontSize: 27,
                    ),
                  ),
                ),
              ),

              //Code text field
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.1,
                //Code text field
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 120, vertical: 0),
                    child: TextFormField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      cursorRadius: Radius.circular(50),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val!.length <= 0) {
                          validName = false;
                          return 'هذا الحقل مطلوب';
                        } else if (val.length <= 5) {
                          validName = false;
                          print("groupCode is not valid");
                          return 'الرمز يجب أن يكون من ٦ أرقام أو أكثر';
                        } else {
                          validName = true;
                          if (int.tryParse(val) == null) {
                            return 'Only Number are allowed';
                          }
                          groupCode = int.parse(val);
                        }
                        /*if (loginErr) {
                            return 'البريد الإلكتروني أو كلمة المرور خاطئة';
                          }*/
                        return null;
                      },
                    )),
              ),

              //button
              Container(
                margin: EdgeInsets.all(10),
                height: 60.0,
                //button
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 120, vertical: 0),
                  // ignore: deprecated_member_use
                  child: FlatButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        side: BorderSide(
                            color: Color.fromARGB(255, 129, 190, 255))),
                    onPressed: () async {
                      //group code is shorter than usual
                      if (validName) {
                        print("groupCode before enter join group: $groupCode");
                        String check = await joinGroup(groupCode);
                        //1 means added to the group
                        if (check == '1') {
                          setState(() {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                '/HomePage', (Route<dynamic> route) => false);
                          });
                        }
                      }
                    },
                    padding: EdgeInsets.all(0.0),
                    color: Color.fromARGB(255, 129, 190, 255),
                    textColor: Colors.white,
                    //text of button
                    child: Text(
                      "انضمام ",
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                        fontSize: 27,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String> joinGroup(int groupCode) async {
    //check if there is a group and if user in it .
    String groupId = await widget.db
        .joinGroup(groupCode, widget.user.userId, widget.user.username);
    if (groupId == "-1") {
      return "there is no group has this code!!";
    }

    if (groupId == "0") {
      return "you are in the group!!";
    }
    return "1";
  }
}
