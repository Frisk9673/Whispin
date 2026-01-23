importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Firebaseの設定（firebase_options.dartの内容に合わせる）
firebase.initializeApp({
  apiKey: 'AIzaSyCEUc7al4LO5iNX_i-Q1sTM2yrX44yytmE',
  appId: '1:772148163985:web:253d944a6aef22f319d630',
  messagingSenderId: '772148163985',
  projectId: 'wispin-999',
  authDomain: 'wispin-999.firebaseapp.com',
  storageBucket: 'wispin-999.firebasestorage.app',
  measurementId: 'G-M8KP27B56M',
});

const messaging = firebase.messaging();

// バックグラウンドメッセージの受信
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'Whispin';
  const notificationOptions = {
    body: payload.notification?.body || '新しい通知があります',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// 通知クリック時の処理
self.addEventListener('notificationclick', function(event) {
  console.log('[Service Worker] Notification click received.');
  event.notification.close();

  // 通知データに基づいてアプリを開く
  event.waitUntil(
    clients.openWindow('/')
  );
});