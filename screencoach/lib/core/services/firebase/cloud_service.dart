import 'dart:ffi';

import 'package:screencoach/core/model/dnsmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAPIService {

  /// Adding a DNS to cloud
  Future<DocumentReference> addDNS(Map<String, dynamic> dnsInfo) {
    CollectionReference collection = FirebaseFirestore.instance.collection("dns");
    var value = collection.add(dnsInfo);
    return value;
  }


  /// Following method will fetch all the DNS from the Firebase
   Future<List<DNSModel>> fetchDNSList() async {
     List<DocumentSnapshot> tempList;
     List<DNSModel> list;
     final groupCollection = FirebaseFirestore.instance.collection('dns');
     QuerySnapshot collectionSnapshot = await groupCollection.get();
     tempList = collectionSnapshot.docs;
     list = List<DNSModel>.generate(
         tempList.length, (index) => DNSModel.fromSnapshot(tempList[index])
     );
     print("Got the list : ${list}");
     return list;
   }

}