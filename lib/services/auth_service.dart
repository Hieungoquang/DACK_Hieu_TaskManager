import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> register (String email, String password)async{
    try{
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'createdAt': Timestamp.now(),
      });
      return null;
      } catch(e){
      return e.toString();
    }
  }

  Future<String?> login(String email, String password)async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e){
      return e.toString();
    }
  }

  Future<String?> logout()async{
    await _auth.signOut();
  }
}