import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_redux/redux/actions.dart';
import 'package:firebase_redux/redux/app_state.dart';
import 'package:redux_epics/redux_epics.dart';
import 'package:rxdart/rxdart.dart';

final allEpics = combineEpics<AppState>([counterEpic, incrementEpic]);

Observable<int> getUserClicks() {
  return new Observable(Firestore.instance.document("users/gunar").snapshots) // 5
      .map((DocumentSnapshot doc) => doc['counter'] as int); // 6
}

Stream<dynamic> counterEpic(Stream<dynamic> actions, EpicStore<AppState> store) {
  return new Observable(actions) // 1
      .ofType(new TypeToken<RequestCounterDataEventsAction>()) // 2
      .flatMapLatest((RequestCounterDataEventsAction requestAction) { // 3
    return getUserClicks() // 4
        .map((counter) => new CounterOnDataEventAction(counter)) // 7
        .takeUntil(actions.where((action) => action is CancelCounterDataEventsAction)); // 8
  });
}

Stream<dynamic> incrementEpic(Stream<dynamic> actions, EpicStore<AppState> store) {
  return new Observable(actions)
      .ofType(new TypeToken<IncrementCounterAction>())
      .flatMap((_) {
    return new Observable.fromFuture(Firestore.instance.document("users/gunar")
        .updateData({'counter': store.state.counter + 1})
        .then((_) => new CounterDataPushedAction())
        .catchError((error) => new CounterOnErrorEventAction(error)));
  });
}