# test-app-flutter
Refactored Flutter Template App that allows for switching between the cloud and edge servers.

## How to set up

1. Download this repo to a local directory
2. Download and extract the contents of the flutter "update base URL" SDK archive into a
   `flutter-update-baseurl` directory under the same parent directory where this repo is stored.
3. Open the pubspec.yaml file and verify the realm dependency path points to your directory where
   the SDK was extracted:

```
  realm:
    path: ../flutter-update-baseurl/realm
```

4. Start up the edge server using the instructions online and the provided `config.json` file in
   the _edge/_ directory. This points to a demo Realm app that can be used with this demo app.

**IMPORTANT:** Only one Edge Server instance can be running at a time with the provided `config.json`
file.

5. Update the `edgeServer` constant in _lib/realm/realm\_services.dart_ file to point to the
   hostname or ip address of the edge server started in step 4.
6. Update the flutter app dependencies by running `flutter pub get` from the top level
   _test-app-flutter/_ directory.

## Running the Demo App

1. Start the flutter app by running `flutter run`.
2. Log in using a new user or the default user credentials:

> username: `testuser4@test.com`

> password: `testpass`

3. The "cloud" button in the App Bar will switch between the cloud (filled) or edge (circle)
   servers and the list will be updated with the contents from that server. The confirmation
   of the server used will be printed on the command line.
4. Verify everything is working properly by using the offline/online (Wifi) button in the
   App Bar or using the "Show All Tasks" switch. The command line will show information
   about when either of these items is selected or changed.
