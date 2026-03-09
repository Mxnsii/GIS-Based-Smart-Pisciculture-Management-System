import 'package:cloud_firestore/cloud_firestore.dart';

void injectDummyComplaint() async {
  try {
    final collection = FirebaseFirestore.instance.collection('complaints');

    // Number 1: Pending
    await collection.add({
      'activityType': 'Fishing in No-Fishing Area (Restricted)',
      'description': 'Saw a large trawler pulling nets near the CRZ boundary.',
      'id': 'dummy-id-pending',
      'isAnonymous': true,
      'reporterName': 'Anonymous',
      'status': 'Pending',
      'timestamp': FieldValue.serverTimestamp(),
      'vesselType': 'Big Net Fishing Boat (Trawler)',
      'location': const GeoPoint(15.2993, 74.1240),
    });

    // Number 2: Reviewed
    await collection.add({
      'activityType': 'Boat Without Fishing License',
      'description': 'Small blue boat spotted with no visible registration number.',
      'id': 'dummy-id-reviewed',
      'isAnonymous': false,
      'reporterName': 'Raj Kumar',
      'status': 'Reviewed',
      'timestamp': FieldValue.serverTimestamp(),
      'vesselType': 'Small / Unknown Boat',
      'location': const GeoPoint(15.3500, 73.9000),
    });

    // Number 3: Action Taken
    await collection.add({
      'activityType': 'Using Illegal Fishing Nets / Gear',
      'description': 'Found discarded fine-mesh nets near the reef.',
      'id': 'dummy-id-action',
      'isAnonymous': false,
      'reporterName': 'Anita Singh',
      'status': 'Action Taken',
      'timestamp': FieldValue.serverTimestamp(),
      'vesselType': 'Other Boat',
      'location': const GeoPoint(15.4000, 73.8000),
    });

    // Number 4: Dismissed
    await collection.add({
      'activityType': 'Two Boats Exchanging Fish in Sea',
      'description': 'Looked suspicious but might be a local transfer.',
      'id': 'dummy-id-dismissed',
      'isAnonymous': true,
      'reporterName': 'Anonymous',
      'status': 'Dismissed',
      'timestamp': FieldValue.serverTimestamp(),
      'vesselType': 'Boat Surrounding Fish with Net (Purse Seiner)',
      'location': const GeoPoint(15.4500, 73.7000),
    });

    print("Successfully injected 4 dummy complaints with different statuses.");
  } catch (e) {
    print("Error injecting complaints: $e");
  }
}
