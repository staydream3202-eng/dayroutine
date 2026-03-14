import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/routine.dart';

class RoutineService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _routines(String uid) =>
      _db.collection('users').doc(uid).collection('routines');

  Stream<List<Routine>> getRoutines(String uid) {
    return _routines(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          return Routine.fromJson({...data, 'id': doc.id});
        }).toList());
  }

  Future<void> addRoutine(String uid, Routine routine) async {
    final data = routine.toJson()..remove('id');
    await _routines(uid).add(data);
  }

  Future<void> deleteRoutine(String uid, String routineId) async {
    await _routines(uid).doc(routineId).delete();
  }

  Future<void> updateRoutine(String uid, Routine routine) async {
    final data = routine.toJson()..remove('id');
    await _routines(uid).doc(routine.id).update(data);
  }
}