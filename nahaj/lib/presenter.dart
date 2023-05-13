// Import the firebase_core and cloud_firestore plugin
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nahaj/HomePage/homePage.dart';
import 'package:nahaj/NahajClasses/classes.dart' as child;
import 'package:shared_preferences/shared_preferences.dart';
import 'NahajClasses/Chats.dart';

class Presenter extends ChangeNotifier {
  late FirebaseFirestore firestore;
  late FirebaseStorage firestorage;
  late FirebaseAuth fireAuth;
  late CollectionReference user;
  //late CollectionReference groups;

  Presenter() {
    firestore = FirebaseFirestore.instance;
    firestorage = FirebaseStorage.instance;
    fireAuth = FirebaseAuth.instance;
    user = firestore.collection('user');
  }
  //------------User---------------

  //sign up 1 (add the user in Auth)
  Future createNewUser(String name, String email, String password) async {
    try {
      UserCredential result = await fireAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      print("createNewUser, database page");
      print(result.user);
      //User user = result.user;
      await addNewUser(name, email, result.user!.uid);
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('The account already exists for that email, database page');
      }
    } catch (e) {
      print('database page \n' + e.toString());
    }
  }

  //sign up 2 (add the user in Firestore) ✅
  Future<void> addNewUser(String name, String email, String uid) async {
    // Call the user's CollectionReference to add a new user
    return await user
        .doc(uid)
        .set({
          'name': name,
          'email': email,
          //default avatar values:
          'avatar':
              "https://firebasestorage.googleapis.com/v0/b/nahaj-6104c.appspot.com/o/Avatar%2Fowl.png?alt=media&token=1e5f590d-ce96-4f4a-82d0-5a455d197585",
          'level': 0,
          'userId': uid,
        })
        .then((value) => createUserScore(uid))
        .catchError(
            (error) => print("database page, Failed to add user: $error"));
  }

  Future<void> createUserScore(String uid) async {
    List<String> expIDs = [];
    await firestore.collection('Experiments').get().then((value) {
      for (var doc in value.docs) {
        expIDs.add(doc.id);
      }
    });
    for (var expID in expIDs) {
      user
          .doc(uid)
          .collection('UserScore')
          .doc(expID)
          .set({'UserScore': 0}).then((value) => print('in create user score'));
    }
  }

  //sign in ✅
  Future loginUser(String email, String password) async {
    try {
      UserCredential result = await fireAuth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print('database page, ' + e.toString());
    }
  }

  //reset password function (in Auth)
  Future<void> resetPassword(String email) async {
    try {
      await fireAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('database page, ' + e.toString());
    }
  }

  void changePassword(String password) async {
    var currentUser = fireAuth.currentUser;
    currentUser!.updatePassword(password).then((_) {
      print("Successfully changed password");
    }).catchError((error) {
      print("Password can't be changed" + error.toString());
    });
  }

  void changeEmail(String email, String userId) async {
    var currentUser = fireAuth.currentUser;
    currentUser!.updateEmail(email).then((_) {
      //change in user collection

      var docRef = firestore.collection('user').doc(userId);
      print('docRef: $docRef');

      docRef.update({
        "email": email,
      });

      print("Successfully changed email");
    }).catchError((error) {
      print("email can't be changed" + error.toString());
    });
  }

  void changeUserName(String userName, String userId) async {
    var docRef = firestore.collection('user').doc(userId);
    print('docRef: $docRef');

    docRef.update({
      "name": userName,
    });

    print("Successfully changed userName");
  }

  Future<bool> changeAvatar(String urlAvatar, String userId) async {
    var docRef = firestore.collection('user').doc(userId);
    print('docRef: $docRef');

    await docRef.update({
      "avatar": urlAvatar,
    });

    print("Successfully changed avatar");
    return true;
  }

//update user level after experiment✅
  Future updateUserLevel(String userId, int level) async {
    firestore.collection('user').doc(userId).update({'level': level});
  }

  //Store user info in session
  Future<dynamic> userInfo(String uid) async {
    String name = '1';
    String email = '1';
    String avatar = '1';
    int level = 0;

    try {
      await user.doc(uid).get().then((value) {
        if (value.exists) {
          print('read from firestore: \n ' +
              value.get("email") +
              ' ' +
              value.get("name") +
              ' ' +
              value.get("avatar"));
          name = value.get('name');
          email = value.get("email");
          avatar = value.get("avatar");
          level = value.get("level");
        } else {
          return false;
        }
      });
    } catch (e) {
      print(e.toString());
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('userId', uid);
    prefs.setString('username', name);
    prefs.setString('avatar', avatar);
    prefs.setInt('level', level);
    prefs.setString('email', email);
    print('inside get user info' + level.toString());
    return name == '1' ? false : true;
  }

  Future<dynamic> adminInfo(String uid) async {
    String name = '1';
    String email = '1';

    try {
      await firestore.collection('Admin').doc(uid).get().then((value) {
        if (value.exists) {
          print('read from firestore: \n ' +
              value.get("email") +
              ' ' +
              value.get("name"));
          name = value.get('name');
          email = value.get("email");
        } else {
          return false;
        }
      });
    } catch (e) {
      print(e.toString());
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('userId', uid);
    prefs.setString('username', name);
    prefs.setString('email', email);
    print('inside get admin info' + email);
    return name == '1' ? false : true;
  }

  Future<List> listOfAvatars() async {
    List avatar = [];
    var collection = firestore.collection('AvatarImages');

    var querySnapshot = await collection.get();

    for (int i = 0; i < querySnapshot.size; i++) {
      avatar.add({
        'url': querySnapshot.docs[i]['url'],
        'level': querySnapshot.docs[i]['level']
      });
    }
    print("avatar inside db: $avatar");
    avatar.sort((a, b) => a['level'].compareTo(b['level']));
    return avatar;
  }

  Future updateUserScore(String expID, int score) async {
    user
        .doc(user_.userId)
        .collection('UserScore')
        .doc(expID)
        .update({'UserScore': score});
  }

  Future<int> getUserScore(String userId, String expId) async {
    var doc = await user.doc(userId).collection('UserScore').doc(expId).get();
    int score = doc.get('UserScore') ?? 0;
    print('getUserScore ' + score.toString());
    return score;
  }

  Future<int> getAllUserScores(String userId) async {
    int totalUserScore = 0;
    var docs = await user.doc(userId).collection('UserScore').get();
    for (var doc in docs.docs) {
      int score = doc.get('UserScore') ?? 0;
      totalUserScore += score;
    }
    return totalUserScore;
  }

  //Signout
  Future signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    await fireAuth.signOut();
  }

  //Get avatar image from Firestorage
  Future<String> loadImage(String path) async {
    //path is the folder after the root on storage firebase
    //name of the image with extention
    return await firestorage.ref(path).getDownloadURL();
  }

  Future<String> storeImage(String destination, File path) async {
    try {
      Reference ref = firestorage.ref(destination);
      print('path.toString()' + path.toString());

      await ref.putFile(path);
      String downloadURL = await ref.getDownloadURL();
      return downloadURL;
    } on FirebaseException catch (e) {
      print(
          "error occure when store image in firestorage, method:storeImage class: DB error: $e");
    }
    return "-1";
  }

  //------------Group---------------

  //get groups of the user ✅
  Stream<List<child.Groups>> getGroupsList(String uid, String uName) {
    Map member = {'userId': uid};

    return firestore
        .collection('Groups')
        .where('members', arrayContains: member)
        .snapshots()
        .map((snapShot) => snapShot.docs
            .map((document) => child.Groups.fromJson(document.data()))
            .toList());
  }

//creat groups for the user ✅
  Future<void> createGroup(int code, String groupName, String leaderName,
      String leaderId, String pathOfImage) async {
    //add to group collection
    final groupDocument = firestore.collection('Groups').doc();

    List<Map> members = [
      {
        'userId': leaderId,
      }
    ];

    child.Groups obj = new child.Groups(
        goupCode: code,
        groupId: groupDocument.id,
        groupName: groupName,
        leaderId: leaderId,
        leaderName: leaderName,
        groupImage: pathOfImage,
        members: members);

    groupDocument
        .set(obj.toJson())
        .then((value) => print("Group created"))
        .catchError((error) => print("Failed to create group: $error"));
    //to add more on members array using groupDocument.updateData rather than groupDocument.set
    createChat(groupDocument.id, groupName);
  }

  Future<bool> checkGroupCode(int code) async {
    bool isFound = false;
    //read the list of groups from
    QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
        .collection('Groups')
        .where('code', isEqualTo: code)
        .get();

    if (snapshot.docs.length >= 1) {
      print("inside checkGroupCode more than one doc have the same code ");
      isFound = true;
    } else {
      print("only one unique value");
    }

    return isFound;
  }

  Future<String> joinGroup(
      int groupCode, String userId, String userName) async {
    print(
        "in (joinGroup,DB) groupId: $groupCode, userID: $userId, userName: $userName");

    String groupId = await findGroup(groupCode);

    if (groupId == '-1') {
      return '-1';
    }

    var docRef = firestore.collection('Groups').doc(groupId);
    print('docRef: $docRef');

    var doc = await docRef.get();
    var data = doc.data() as Map<String, dynamic>;
    var inGroup = false;

    List<Map> members = [
      {
        'userId': userId,
      }
    ];

    List membersInDB = data['members'] ?? [{}];
    print("****************************");
    membersInDB.forEach((map) {
      print("$map:");
      if (map['userId'] == userId) {
        print("inside if v == userId value");
        inGroup = true;
      }
      members.add(map);
    });

    print("****************************");

    if (!inGroup) {
      print("inside !inGroup");
      docRef.update({
        "members": members,
        //"membersCounter": ++data['membersCounter'],
      });
    }
    return 'join group success';
  }

  Future<String> findGroup(int groupCode) async {
    var collection =
        firestore.collection('Groups').where('code', isEqualTo: groupCode);

    var querySnapshot = await collection.get();
    if (querySnapshot.docs.length == 0) {
      print(
          "there is no group has this code, (findGroup, database)\n$querySnapshot\n${querySnapshot.docs}");
      return '-1';
    }
    return querySnapshot.docs[0].reference.id;
  }

  removeUserFromGroup(String groupId, String userId) {
    var docRef = firestore.collection('Groups').doc(groupId);
    List deletedMember = [];
    deletedMember.add({
      "userId": userId,
    });
    docRef.update({
      "members": FieldValue.arrayRemove(deletedMember),
    });
  }

  removeGroup(String groupId) {
    //remove from collection chat
    firestore
        .collection('Chats')
        .doc(groupId)
        .delete() // <-- Delete
        .then((_) => print('Deleted from chat collection'))
        .catchError((error) => print('Delete failed: $error'));

    //remove from collection Group
    firestore
        .collection('Groups')
        .doc(groupId)
        .delete() // <-- Delete
        .then((_) => print('Deleted from group collection'))
        .catchError((error) => print('Delete failed: $error'));
  }

  Stream<List<child.User>> getMembers(List members) {
    print("inside getMembers: \n members list before fetch: $members");
    var x = firestore
        .collection('user')
        .where('userId', whereIn: members)
        .snapshots()
        .map((snapShot) => snapShot.docs
            .map((document) => child.User.fromJson(document.data()))
            .toList());
    print("inside getMembers: \n members list after fetch: $x");
    return x;
  }

  //------------Chat---------------

  void createChat(String groupId, String groupName) {
    //add to group collection
    if (groupId == '-1') {
      return;
    }
    final chatDocument = firestore.collection('Chats').doc(groupId);
    var addChat = Map<String, dynamic>();
    addChat['groupId'] = groupId;
    addChat['groupName'] = groupName;

    chatDocument
        .set(addChat)
        .then((value) => print("Groupchat created"))
        .catchError((error) => print("Failed to create groupchat: $error"));
  }

  Future uploadMessage(
      String groupId, String userId, String userName, String message) async {
    if (groupId == '-1') {
      return;
    }

    var refMessages =
        firestore.collection('Chats').doc(groupId).collection('Messages').doc();
    print('docRef: $refMessages');

    Chat c = new Chat(
        userId: userId,
        username: userName,
        message: message,
        createdAt: DateTime.now());

    refMessages
        .set(c.toJson())
        .then((value) => print("Groupchat created"))
        .catchError((error) => print("Failed to create groupchat: $error"));
  }

  Stream<List<Chat>> getMessagesList(String groupId) {
    return firestore
        .collection('Chats')
        .doc(groupId)
        .collection('Messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapShot) => snapShot.docs
            .map((document) => Chat.fromJson(document.data()))
            .toList());
  }

  //------------Experiment---------------

  Stream<List<child.ExperimentInfo>> getExperiments(String category) {
    return firestore
        .collection('Experiments')
        .where('Category', isEqualTo: category)
        .snapshots()
        .map((snapShot) => snapShot.docs
            .map((document) => child.ExperimentInfo.fromJson(document.data()))
            .toList());
  }

  Stream<List<child.ExperimentInfo>> getExp() {
    return firestore.collection('Experiments').snapshots().map((snapShot) =>
        snapShot.docs
            .map((document) => child.ExperimentInfo.fromJson(document.data()))
            .toList());
  }

  Future updateExpName(String expID, String name) async {
    await firestore.collection('Experiments').doc(expID).update({'Name': name});
  }

  Future updateExpCategory(String expID, String category) async {
    await firestore
        .collection('Experiments')
        .doc(expID)
        .update({'Category': category});
  }

  Future updateExpInfo(String expID, String info) async {
    await firestore.collection('Experiments').doc(expID).update({'Info': info});
  }

  Future updateExpScor(String expID, int score, int oldExperimentScore) async {
    await firestore
        .collection('Experiments')
        .doc(expID)
        .update({'ExperimentScore': score});
    //update total score of exp
    updateTotalScore(expID, (score - oldExperimentScore));
  }

  //------------Question---------------

  Stream<List<child.Question>> getQuestions(String expID) {
    return firestore
        .collection('Experiments')
        .doc(expID)
        .collection('Questions')
        .snapshots()
        .map((snapShot) => snapShot.docs
            .map((document) => child.Question.fromJson(document.data()))
            .toList());
  }

  Future updateQuesAns(
      String expID,
      String quesID,
      String ques,
      String ans1,
      String ans2,
      String ans3,
      String ans4,
      String correctAns,
      int score,
      int oldScore) async {
    return firestore
        .collection('Experiments')
        .doc(expID)
        .collection('Questions')
        .doc(quesID)
        .update({
      'Question': ques,
      'Answer1': ans1,
      'Answer2': ans2,
      'Answer3': ans3,
      'Answer4': ans4,
      'CorrectAnswer': correctAns,
      'Score': score
    }).then((value) async {
      //update exp total score
      await updateTotalScore(expID, score - oldScore);
      print("inside updateQuesAns after call updateTotalScore");
    });
  }

  deleteQuestion(String expID, String quesID, int quesScore) async {
    //remove from collection Question
    await firestore
        .collection('Experiments')
        .doc(expID)
        .collection('Questions')
        .doc(quesID)
        .delete() // <-- Delete
        .then((_) => print('Deleted questiong done'))
        .catchError((error) => print('Delete failed: $error'));
    //delete score from total score exp
    updateTotalScore(expID, -quesScore);
  }

  Future<void> addNewQuestion(
      String question,
      String correctAnswer,
      String answer1,
      String answer2,
      String answer3,
      String answer4,
      int score,
      String expID) async {
    // Call the user's CollectionReference to add a new user
    final questionDocument = firestore
        .collection('Experiments')
        .doc(expID)
        .collection('Questions')
        .doc();
    return await questionDocument.set({
      'Question': question,
      'ExpID': expID,
      'QID': questionDocument.id,
      'CorrectAnswer': correctAnswer,
      'Score': score,
      'Answer1': answer1,
      'Answer2': answer2,
      'Answer3': answer3,
      'Answer4': answer4,
    }).then((value) {
      print("User Added, database page");
      updateTotalScore(expID, score);
    }).catchError(
        // ignore: invalid_return_type_for_catch_error
        (error) => print("database page, Failed to add user: $error"));
    //update total score of exp
  }

  Future updateTotalScore(String expID, int score) async {
    await firestore.collection('Experiments').doc(expID).get().then((value) {
      int totlaScore = value.get('TotlaScore');
      print("TotlaScore inside updateTotalScore $totlaScore score: $score");
      firestore
          .collection('Experiments')
          .doc(expID)
          .update({'TotlaScore': (totlaScore + score)});
    });
  }
}
