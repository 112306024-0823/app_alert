// firebase-messaging-sw.js
// Service Worker for Firebase Cloud Messaging on Web Platform

importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker
// Using the web configuration from firebase_options.dart
firebase.initializeApp({
  apiKey: "AIzaSyDMvTHAPe4NcXQ-VAkeHsIJD-ypBIQsPn8",
  authDomain: "appalert-db9d5.firebaseapp.com",
  projectId: "appalert-db9d5",
  storageBucket: "appalert-db9d5.firebasestorage.app",
  messagingSenderId: "815829848221",
  appId: "1:815829848221:web:f3884ed7459f4e381a0474",
  measurementId: "G-329RLWWB8H"
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'Notification';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'fcm-notification',
    requireInteraction: false,
    silent: false
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received.');
  
  event.notification.close();
  
  // Focus the app if it's already open, otherwise open a new window
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url === '/' && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});

