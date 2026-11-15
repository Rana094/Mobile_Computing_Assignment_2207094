import FirebaseAuth
import FirebaseCore
import SwiftUI

@main
struct SimpleTodoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            LaunchView(delegate: delegate)
                .tint(.indigo)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    @Published private(set) var auth: Auth?
    @Published private(set) var configurationError: String?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        guard let options = FirebaseOptions.defaultOptions() else {
            configurationError = "Add GoogleService-Info.plist to the SimpleTodo target in Xcode."
            return true
        }

        if let appBundleID = Bundle.main.bundleIdentifier,
           options.bundleID != appBundleID {
            print("Note: GoogleService-Info.plist bundleID (\(options.bundleID)) differs from app bundle identifier (\(appBundleID)).")
        }

        if FirebaseApp.app() == nil {
            FirebaseApp.configure(options: options)
        }
        auth = Auth.auth()
        return true
    }
}

private struct LaunchView: View {
    @ObservedObject var delegate: AppDelegate

    var body: some View {
        if let auth = delegate.auth {
            SessionView(auth: auth)
        } else if let message = delegate.configurationError {
            ContentUnavailableView(
                "Set Up Firebase",
                systemImage: "gearshape",
                description: Text(message)
            )
        } else {
            ProgressView("Starting…")
        }
    }
}

private struct SessionView: View {
    let auth: Auth

    @State private var userID: String?
    @State private var isCheckingSession = true
    @State private var listener: AuthStateDidChangeListenerHandle?

    init(auth: Auth) {
        self.auth = auth
    }

    var body: some View {
        ZStack {
            if isCheckingSession {
                ProgressView("Signing you in…")
            } else if let userID {
                TodoScreen(userID: userID) {
                    try auth.signOut()
                }
                .id(userID)
            } else {
                AuthView { mode, email, password in
                    switch mode {
                    case .login:
                        _ = try await auth.signIn(withEmail: email, password: password)
                    case .signUp:
                        _ = try await auth.createUser(withEmail: email, password: password)
                    }
                }
            }
        }
        .onAppear {
            guard listener == nil else { return }
            listener = auth.addStateDidChangeListener { _, user in
                userID = user?.uid
                isCheckingSession = false
            }
        }
        .onDisappear {
            if let listener {
                auth.removeStateDidChangeListener(listener)
                self.listener = nil
            }
        }
    }
}
