# Simple To-Do

An iPhone app for the Mobile Computing assignment. SwiftUI provides the screens, Firebase Authentication handles email and password accounts, and Cloud Firestore stores each account’s tasks.

## Run on a Mac

Use Xcode 26.2 or later and an iPhone simulator running iOS 17 or later. Xcode downloads the Firebase packages when you open `SimpleTodo.xcodeproj`. [Firebase SDK requirements](https://firebase.google.com/support/release-notes/ios#version_1300_-_october_7_2026)

1. Create a project in the [Firebase console](https://console.firebase.google.com/) and register an Apple app with bundle ID `com.assignment.simpletodo`. If you change the identifier in Xcode under **Signing & Capabilities**, register the new identifier in Firebase as well. [Firebase setup for Apple apps](https://firebase.google.com/docs/ios/setup)
2. Open `SimpleTodo.xcodeproj` in Xcode. Drag the downloaded `GoogleService-Info.plist` into the **SimpleTodo** group. Choose to copy the file into the project and add it to the **SimpleTodo** target.
3. In Firebase **Authentication → Sign-in method**, enable **Email/Password**. [Firebase password authentication](https://firebase.google.com/docs/auth/ios/password-auth)
4. In Firebase **Firestore Database**, create the default **Standard** database in production mode. Open **Rules**, paste the contents of `firestore.rules`, and select **Publish**. [Firestore setup](https://firebase.google.com/docs/firestore/quickstart)
5. Select the **SimpleTodo** scheme and an iPhone simulator, then press **⌘R**.

## Demo

1. Create an account and add two tasks using the field at the bottom. A field containing only spaces cannot be submitted.
2. Tap the trash button on one task. Log out and log back in to confirm the remaining task is still there.
3. Create a second account and confirm it starts with an empty list.

For a UI-only demo, Xcode’s canvas previews in `AuthView.swift` show the login and sign-up screens. The preview in `TodoScreen.swift` lets you add and delete sample tasks without Firebase configuration.

Firestore stores each task under `users/{userID}/todos/{todoID}`, with a `title` and a server-generated `createdAt` timestamp. The list updates from a Firestore listener and shows newer tasks first. The included rules allow each signed-in user to read, create, and delete tasks in their own list. [Firestore owner-based rules](https://firebase.google.com/docs/firestore/security/rules-conditions)
