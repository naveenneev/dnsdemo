import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

DNSModel dnsModelFromJson(String str) => DNSModel.fromJson(json.decode(str));
String dnsModelToJson(DNSModel data) => json.encode(data.toJson());

class DNSModel {

  String address;
  DocumentReference reference;

  DNSModel({this.address});


  factory DNSModel.fromJson(Map<String, dynamic> json) => DNSModel(
    address: json["address"],
  );


  DNSModel.fromMap(Map<String, dynamic> json, {this.reference})
    : address = json["address"];


  DNSModel.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data(), reference: snapshot.reference);

  Map<String, dynamic> toJson() => {
    "address": address,
  };
}