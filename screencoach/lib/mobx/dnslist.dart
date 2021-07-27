import 'package:mobx/mobx.dart';
import 'package:screencoach/core/model/dnsmodel.dart';
import 'package:screencoach/core/services/firebase/cloud_service.dart';

part 'DNSList.g.dart';

class DNSList = DNSListBase with _$DNSList;

abstract class DNSListBase with Store {

  @observable
  List<DNSModel> dnsList;

  @action
  void fetchDNSList() {
    FirebaseAPIService().fetchDNSList().then((value) => {
      this.dnsList = value
    });
  }
}