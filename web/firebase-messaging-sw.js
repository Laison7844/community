importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDkWCKoy1JIWRaE8d9GjtPDFeY8tiQfxYs",
  authDomain: "church-5d638.firebaseapp.com",
  projectId: "church-5d638",
  storageBucket: "church-5d638.firebasestorage.app",
  messagingSenderId: "318809620975",
  appId: "1:318809620975:web:6c6b6bad0329265ef6b61a",
  measurementId: "G-C2PP2ZNKJH",
});

const messaging = firebase.messaging();

// Optional background message handler
messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message:", payload);
  const notificationTitle =
    payload.notification && payload.notification.title
      ? payload.notification.title
      : (payload.data && payload.data.title ? payload.data.title : "CSI Church Community");

  const notificationOptions = {
    body:
      payload.notification && payload.notification.body
        ? payload.notification.body
        : (payload.data && payload.data.body ? payload.data.body : ""),
    icon: "/favicon.png",
    data: payload.data || {},
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
