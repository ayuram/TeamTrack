import admin = require("firebase-admin");
import * as functions from "firebase-functions";
import {ftcAPIKey} from "./api/ftcAPIKey";
// Start writing Firebase Functions
// https://firebase.google.com/docs/functions/typescript
admin.initializeApp();

// put event in desired user's inbox
export const shareEvent = functions.https.onCall(async (data, context) => {
  functions.logger.info("Event share", {structuredData: true});
  if (!context.auth) { // if not authenticated
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User not logged in"
    );
  }
  const sender = await admin
      .auth()
      .getUser(context.auth.uid);
  const recipient = await admin
      .auth()
      .getUserByEmail(data.email);
  if (recipient == null) { // if recipient doesn't exist
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Requested user does not exist"
    );
  }
  if (sender.uid == recipient.uid) { // if sender and recipient are the same
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Cannot send an event to yourself"
    );
  }
  await admin.database().ref()
      .child(`Events/${data.gameName}/${data.id}/Permissions/${recipient.uid}`)
      .set({
        "role": data.role,
        "name": recipient.displayName,
        "email": recipient.email,
        "photoURL": recipient.photoURL,
      }); // update permissions for recepient
  const meta = {
    "id": data.id,
    "name": data.name,
    "authorEmail": data.authorEmail,
    "authorName": data.authorName,
    "senderName": sender.displayName ?? "Unknown",
    "senderEmail": sender.email ?? "Unknown",
    "senderID": sender.uid,
    "sendTime": admin.firestore.FieldValue.serverTimestamp(),
    "type": data.type,
    "gameName": data.gameName,
  };
  const ref = admin.firestore().collection("users").doc(recipient.uid);
  let tokens:string[] = [];
  let allowSend = true;
  const returnVal = await admin.firestore().runTransaction(async (t) => {
    const doc = await t.get(ref);
    const newInbox = doc?.data()?.inbox;
    // save the fcm tokens to send to
    tokens = doc?.data()?.FCMtokens;
    const blocked = doc?.data()?.blockedUsers;
    // allow send if not blocked and not in inbox and not already shared
    allowSend = blocked[sender.uid] == null && newInbox[data.id] == null &&
      doc?.data()?.events[data.id] == null;
    if (allowSend) {
      newInbox[data.id] = meta;
    }
    t.update(ref, {inbox: newInbox});
  });
  const notification = {
    title: `New Event: ${meta.name ?? "Unknown"} `,
    body: `${sender.displayName ?? "Unknown"} has shared an event with you`,
  };
  const message = {
    tokens: tokens,
    notification: notification,
  };
  if (tokens.length != 0 && allowSend) {
    await admin.messaging().sendMulticast(message); // send notifications
  }
  return returnVal;
});

// update creator's permissions and add the new event to creator's events list
export const nativizeEvent = functions.database
    .ref("/Events/{gameName}/{event}")
    .onCreate(async (snap, context) => {
      const event = snap.val();
      const ref = admin.firestore().collection("users")
          .doc(context.auth?.uid ?? "");
      const user = await admin.auth().getUser(context.auth?.uid ?? "");
      snap.ref.child("Permissions").child(context.auth?.uid ?? "").set({
        "role": "admin",
        "name": user.displayName,
        "email": user.email,
        "photoURL": user.photoURL,
      });
      return admin.firestore().runTransaction(async (t) => {
        const doc = await t.get(ref);
        const events = doc.data()?.events;
        events[event.id] = {
          "name": event.name,
          "sendDate": admin.database.ServerValue.TIMESTAMP,
          "authorName": event.authorName,
          "authorEmail": event.authorEmail,
          "id": event.id,
          "type": event.type,
          "gameName": event.gameName,
        };
        t.update(doc.ref, {events: events});
      });
    });

// Delete event from user's inbox
export const deleteEvent = functions.database
    .ref("/Events/{gameName}/{event}")
    .onDelete((snap) => {
      const event = snap.val();
      const users: Array<string> = [];
      for (const [key] of Object.entries(event.Permissions)) {
        users.push(key);
      }
      return admin.firestore().runTransaction(async (t) => {
        const refs = users.map((user) => {
          return admin.firestore().collection("users").doc(user);
        });
        const allDocs = new Map<FirebaseFirestore.DocumentSnapshot<
        FirebaseFirestore.DocumentData>, unknown>();
        for (const ref of refs) {
          const doc = await t.get(ref);
          const events = doc.data()?.events;
          delete events[event.id];
          allDocs.set(doc, events);
        }
        for (const doc of allDocs.keys()) {
          t.update(doc.ref, {events: allDocs.get(doc)});
        }
      });
    });

export const createUser = functions.auth.user().onCreate(async (user) => {
  return admin.firestore().collection("users").doc(user.uid).set({
    inbox: {},
    events: {},
    blockedUsers: {},
    FCMtokens: [],
  });
});

// Delete user's document
export const deleteUser = functions.auth.user().onDelete(async (user) => {
  return admin.firestore().collection("users").doc(user.uid).delete();
});

export const fetchAPI = functions.https.onCall((data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User not logged in"
    );
  }
  const url = new URL("https://ftc-api.firstinspires.org/v2.0/");
  return fetch(url.toString(), {
    headers: {Authorization: `Basic ${ftcAPIKey}`},
  });
});
