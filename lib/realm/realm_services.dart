import 'package:flutter_todo/realm/schemas.dart';
import 'package:realm/realm.dart';
import 'package:flutter/material.dart';

class RealmServices with ChangeNotifier {
  static const String queryAllName = "getAllItemsSubscription";
  static const String queryMyItemsName = "getMyItemsSubscription";
  static const String cloudServer = "https://realm.mongodb.com";
  static const String edgeServer = "http://172.16.101.112";
  static const String email = "testuser4@test.com";
  static const String password = "testpass";

  bool showAll = false;
  bool offlineModeOn = false;
  bool useCloud = true;
  bool isWaiting = false;
  late Realm realm;
  User? currentUser;
  App app;

  RealmServices(this.app) {
    print("RealmServices()");
    if (app.currentUser != null || currentUser != app.currentUser) {
      currentUser ??= app.currentUser;
      realm = Realm(Configuration.flexibleSync(currentUser!, [Item.schema]));
      showAll = (realm.subscriptions.findByName(queryAllName) != null);
      if (realm.subscriptions.isEmpty) {
        updateSubscriptions();
      }
    }
  }

  Future<void> updateSubscriptions() async {
    realm.subscriptions.update((mutableSubscriptions) {
      mutableSubscriptions.clear();
      if (showAll) {
        mutableSubscriptions.add(realm.all<Item>(), name: queryAllName);
      } else {
        mutableSubscriptions.add(
            realm.query<Item>(r'owner_id == $0', [currentUser?.id]),
            name: queryMyItemsName);
      }
    });
    await realm.subscriptions.waitForSynchronization();
  }

  Future<void> sessionSwitch() async {
    offlineModeOn = !offlineModeOn;
    if (offlineModeOn) {
      realm.syncSession.pause();
      print("OFFLINE");
    } else {
      try {
        isWaiting = true;
        notifyListeners();
        realm.syncSession.resume();
        await updateSubscriptions();
        print("ONLINE with server base url: ${app.getBaseUrl()}");
      } finally {
        isWaiting = false;
      }
    }
    notifyListeners();
  }

  Future<bool> cloudEdgeSwitch() async {
    if (!offlineModeOn && !realm.isClosed) {
      useCloud = !useCloud;
      try {
        isWaiting = true;
        realm.syncSession.pause();
        final serverUrl = useCloud ? cloudServer : edgeServer;
        print("Updating base url to: $serverUrl");
        await app.updateBaseUrl(Uri.parse(serverUrl));
        User loggedInUser = await app.logIn(Credentials.emailPassword(email, password));
        print("Using server base url: ${app.getBaseUrl()}");
        if (app.currentUser == null && currentUser != loggedInUser) {
          print("User is either null or not the same as the original user");
          await close();
          return false;
        }
        realm.syncSession.resume();
      } catch (e) {
        print("Error occurred while switching servers: $e");
        await close();
        return false;
      } finally {
        isWaiting = false;
      }
      notifyListeners();
    }
    print("Done switching servers");
    return true;
  }

  Future<void> switchSubscription(bool value) async {
    showAll = value;
    if (!offlineModeOn) {
      try {
        isWaiting = true;
        notifyListeners();
        await updateSubscriptions();
      } finally {
        isWaiting = false;
      }
    }
    notifyListeners();
  }

  void createItem(String summary, bool isComplete) {
    final newItem =
        Item(ObjectId(), summary, currentUser!.id, isComplete: isComplete);
    realm.write<Item>(() => realm.add<Item>(newItem));
    notifyListeners();
  }

  void deleteItem(Item item) {
    realm.write(() => realm.delete(item));
    notifyListeners();
  }

  Future<void> updateItem(Item item,
      {String? summary, bool? isComplete}) async {
    realm.write(() {
      if (summary != null) {
        item.summary = summary;
      }
      if (isComplete != null) {
        item.isComplete = isComplete;
      }
    });
    notifyListeners();
  }

  Future<void> close() async {
    if (currentUser != null) {
      await currentUser?.logOut();
      currentUser = null;
    }
    realm.close();
  }

  @override
  void dispose() {
    realm.close();
    super.dispose();
  }
}
