//
//  PushNotificationService.swift
//  HatchPlanPro
//
//  Manages push notification registration, FCM token handling, and
//  local notification scheduling. Integrates with Firebase Cloud
//  Messaging for remote push delivery.
//

import Foundation
import Combine
import UserNotifications
import FirebaseMessaging
import FirebaseFirestore

/// Handles push notification registration and local notification scheduling
/// for HatchPlan Pro. Supports both remote (FCM) and local notifications.
final class PushNotificationService: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = PushNotificationService()
    
    /// The current FCM token, if registered.
    @Published var fcmToken: String?
    
    /// Whether push notifications are authorized.
    @Published var isAuthorized: Bool = false
    
    private override init() {
        super.init()
    }
    
    // MARK: - Request Permission
    
    /// Requests notification authorization from the user.
    /// - Parameter completion: Called with `true` if authorized.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if let error = error {
                    print("PushNotificationService: Authorization error — \(error.localizedDescription)")
                }
                completion(granted)
            }
        }
    }
    
    // MARK: - FCM Token
    
    /// Retrieves the current FCM token and saves it to Firestore
    /// for the specified user UID.
    func registerFCMToken(forUserUID uid: String) {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("PushNotificationService: FCM token error — \(error.localizedDescription)")
                return
            }
            
            guard let token = token else { return }
            
            DispatchQueue.main.async {
                self.fcmToken = token
            }
            
            // Save token to Firestore for server-side messaging
            let db = FirebaseFirestore.Firestore.firestore()
            db.collection("users").document(uid).setData([
                "fcmToken": token,
                "tokenUpdatedAt": FirebaseFirestore.FieldValue.serverTimestamp()
            ], merge: true) { error in
                if let error = error {
                    print("PushNotificationService: Failed to save FCM token — \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Local Notifications
    
    /// Schedules a local notification for batch-related events.
    /// - Parameters:
    ///   - title: The notification title.
    ///   - body: The notification body text.
    ///   - identifier: Unique identifier for the notification.
    ///   - timeInterval: Seconds from now to fire the notification.
    func scheduleLocalNotification(title: String, body: String,
                                    identifier: String, timeInterval: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(timeInterval, 1),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("PushNotificationService: Failed to schedule notification — \(error.localizedDescription)")
            }
        }
    }
    
    /// Schedules a critical batch alert notification.
    func scheduleBatchAlert(batchID: String, message: String) {
        scheduleLocalNotification(
            title: "🚨 Batch \(batchID) Alert",
            body: message,
            identifier: "batch_alert_\(batchID)",
            timeInterval: 1
        )
    }
    
    /// Schedules an approval notification for managers.
    func scheduleApprovalNotification(batchID: String, supervisorName: String) {
        scheduleLocalNotification(
            title: "Approval Required",
            body: "\(supervisorName) has submitted Batch \(batchID) for approval.",
            identifier: "approval_\(batchID)",
            timeInterval: 1
        )
    }
    
    /// Removes all pending notifications.
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// Removes delivered notifications from the notification center.
    func clearDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

