//
//  HatchPlanProApp.swift
//  HatchPlanPro
//
//  Created by Nadunika Sharindi on 2026-05-11.
//
import SwiftUI
import CoreData
import FirebaseCore
import FirebaseMessaging
import UserNotifications

/// AppDelegate handles Firebase initialisation and push notification setup.
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialise Firebase
        FirebaseApp.configure()
        
        // Set up push notification delegates
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // MARK: - APNs Token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // MARK: - Foreground Notification Display
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification banner even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }
    
    // MARK: - Notification Tap Handling
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("HatchPlanPro: Notification tapped with payload: \(userInfo)")
        completionHandler()
    }
    
    // MARK: - FCM Token Refresh
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("HatchPlanPro: FCM token refreshed: \(token)")
        PushNotificationService.shared.fcmToken = token
    }
}

@main
struct HatchPlanProApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    let persistenceController = PersistenceController.shared
    @StateObject private var session = AppSessionViewModel()
    
    // Check local storage to see if onboarding is complete
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    if session.isAuthenticated {
                        ContentView()
                    } else if session.needsBiometricUnlock {
                        BiometricUnlockView()
                    } else {
                        LandingView()
                    }
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(session)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .modifier(VoiceOverDynamicTypeModifier(session: session))
            .onAppear {
                session.refreshVoiceOverStatus()
                session.restoreStoredSession()
            }
        }
    }
}

private struct VoiceOverDynamicTypeModifier: ViewModifier {
    @ObservedObject var session: AppSessionViewModel

    func body(content: Content) -> some View {
        if session.isVoiceOverRunning {
            content
        } else {
            content.environment(\.dynamicTypeSize, session.preferredDynamicTypeSize)
        }
    }
}
