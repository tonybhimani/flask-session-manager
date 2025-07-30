// web/firebase-messaging-sw.js

// Import the Firebase SDK (adjust version if needed)
importScripts(
  "https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js"
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js"
);

// Initialize Firebase with your project's configuration
// Replace with your actual Firebase project config
// You can get this from Firebase Console -> Project settings -> Your apps -> Web app -> Firebase SDK snippet -> Config
const firebaseConfig = {
  apiKey: "API_KEY",
  authDomain: "AUTH_DOMAIN",
  projectId: "PROJECT_ID",
  storageBucket: "STORAGE_BUCKET",
  messagingSenderId: "SENDER_ID",
  appId: "APP_ID",
};

firebase.initializeApp(firebaseConfig);

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log(
    "[firebase-messaging-sw.js] Received background message:",
    payload
  );

  // Check for the logout command
  if (payload.data && payload.data.logout_command === "true") {
    console.log(
      "[firebase-messaging-sw.js] Logout command received. Clearing tokens from localStorage."
    );

    // Send a message to all active clients (tabs)
    self.clients
      .matchAll({ includeUncontrolled: true, type: "window" })
      .then((clients) => {
        clients.forEach((client) => {
          // Send to all LOGOUT_COMMAND to all clients
          client.postMessage({
            type: "LOGOUT_COMMAND", // Define a type for your message
            data: payload.data,
          });
        });
      });

    // You might want to display a notification here as well
    const notificationTitle = "Account Logged Out";
    const notificationOptions = {
      body: "Your account has been logged out from all devices for security reasons.",
      icon: "/icons/Icon-192.png", // Path to an app icon in your web/ directory
    };

    // Display the notification
    return self.registration.showNotification(
      notificationTitle,
      notificationOptions
    );
  } else if (payload.notification) {
    // If it's a regular notification message, display it
    const notificationTitle = payload.notification.title || "New Message";
    const notificationOptions = {
      body: payload.notification.body,
      icon: payload.notification.icon || "/icons/Icon-192.png",
      // You can add more options like image, actions, etc.
    };
    return self.registration.showNotification(
      notificationTitle,
      notificationOptions
    );
  }
  // No explicit return for data messages that aren't logout or notifications
  return Promise.resolve();
});

// Important: When working with Flutter, Flutter itself registers its own service worker (`flutter_service_worker.js`).
// The Firebase Messaging service worker needs to be available alongside it.
// Modern browsers are smart enough to manage multiple service workers if they are registered correctly.
// Ensure your index.html refers to your Flutter app's main script correctly, which then handles the Flutter service worker.
// The firebase-messaging-sw.js is automatically picked up by Firebase's SDK.
