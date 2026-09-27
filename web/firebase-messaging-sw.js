importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyB0xtfJMflFm_2pXdxo5sMPncPQgyE9AAM",
  authDomain: "mytijaara-21638.firebaseapp.com",
  databaseURL: "https://mytijaara-21638-default-rtdb.firebaseio.com",
  projectId: "mytijaara-21638",
  storageBucket: "mytijaara-21638.firebasestorage.app",
  messagingSenderId: "1017926959065",
  appId: "1:1017926959065:web:fee8e7af199a1d677e23c8",
  measurementId: "G-6XF74RVXXW"
});

const messaging = firebase.messaging();

messaging.setBackgroundMessageHandler(function (payload) {
    const promiseChain = clients
        .matchAll({
            type: "window",
            includeUncontrolled: true
        })
        .then(windowClients => {
            for (let i = 0; i < windowClients.length; i++) {
                const windowClient = windowClients[i];
                windowClient.postMessage(payload);
            }
        })
        .then(() => {
            const title = payload.notification.title;
            const options = {
                body: payload.notification.score
              };
            return registration.showNotification(title, options);
        });
    return promiseChain;
});
self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});