import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reef_mobile_app/model/account/stored_account.dart';

class StorageService {
  Completer<Box<dynamic>> mainBox = Completer();
  Completer<Box<dynamic>> accountsBox = Completer();

  StorageService() {
    _checkPermission();
    _initAsync();
  }

  Future<dynamic> getValue(String key) =>
      mainBox.future.then((Box<dynamic> box) => box.get(key));

  Future<dynamic> setValue(String key, dynamic value) =>
      mainBox.future.then((Box<dynamic> box) => box.put(key, value));

  Future<dynamic> deleteValue(String key) =>
      mainBox.future.then((Box<dynamic> box) => box.delete(key));

  Future<dynamic> getAccount(String address) =>
      accountsBox.future.then((Box<dynamic> box) => box.get(address));

  Future<List<StoredAccount>> getAllAccounts() => accountsBox.future
      .then((Box<dynamic> box) => box.values.toList().cast<StoredAccount>());

  Future<dynamic> saveAccount(StoredAccount account) => accountsBox.future
      .then((Box<dynamic> box) => box.put(account.address, account));

  Future<dynamic> deleteAccount(String address) =>
      mainBox.future.then((Box<dynamic> box) => box.delete(address));

  _initAsync() async {
    if (await _checkPermission()) {
      _initHive();
    }
  }

  _initHive() async {
    var dir = await getApplicationDocumentsDirectory();
    var path = dir.path + "/hive_store";
    Hive
      ..init(path)
      ..registerAdapter(StoredAccountAdapter());

    mainBox.complete(Hive.openBox('ReefChainBox'));

    // Encryption
    const secureStorage = FlutterSecureStorage();
    var key = await secureStorage.read(key: 'encryptionKey');
    if (key == null) {
      var key = Hive.generateSecureKey();
      await secureStorage.write(
          key: 'encryptionKey', value: base64UrlEncode(key));
    }
    key = await secureStorage.read(key: 'encryptionKey');
    var encryptionKey = base64Url.decode(key!);

    accountsBox.complete(Hive.openBox('AccountsBox',
        encryptionCipher: HiveAesCipher(encryptionKey)));
  }

  Future<bool> _checkPermission() async {
    var status = await Permission.storage.status;
    print('PERMISSION STORAGE=$status');
    if (status.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.
      if (await Permission.storage.request().isGranted) {
        print("PERMISSION GRANTED");
      } else {
        print("PERMISSION DENIED");
      }
    }
    return status.isGranted;
  }
}
