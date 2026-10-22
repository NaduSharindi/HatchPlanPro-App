//
//  CoreDataManager.swift
//  HatchPlanPro
//
//  Provides a clean CRUD interface over Core Data entities for local
//  persistence. Acts as a write-through cache: data is saved locally
//  first for offline access, then synced to Firebase when connectivity
//  is available.
//

import Foundation
import CoreData

/// Manages all Core Data CRUD operations for HatchPlan Pro entities.
/// Uses PersistenceController.shared for the managed object context.
final class CoreDataManager {
    
    // MARK: - Singleton
    static let shared = CoreDataManager()
    private init() {}
    
    /// The main-thread view context from the shared persistence controller.
    private var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }
    
    // MARK: - Save Context
    
    /// Commits any pending changes in the view context.
    func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("CoreDataManager: Failed to save context — \(error.localizedDescription)")
        }
    }
    
    // MARK: - User Profile CRUD
    
    /// Saves or updates a user profile in Core Data.
    func saveUserProfile(uid: String, email: String, fullName: String, role: String, pinConfigured: Bool = false, biometricEnabled: Bool = false) {
        // Check if user already exists
        let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        request.predicate = NSPredicate(format: "uid == %@", uid)
        
        do {
            let existing = try context.fetch(request)
            let user = existing.first ?? CDUser(context: context)
            user.uid = uid
            user.email = email
            user.fullName = fullName
            user.role = role
            user.pinConfigured = pinConfigured
            user.biometricEnabled = biometricEnabled
            user.createdAt = existing.first?.createdAt ?? Date()
            saveContext()
        } catch {
            print("CoreDataManager: Failed to save user profile — \(error.localizedDescription)")
        }
    }
    
    /// Fetches a user profile by UID.
    func fetchUserProfile(uid: String) -> CDUser? {
        let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        request.predicate = NSPredicate(format: "uid == %@", uid)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("CoreDataManager: Failed to fetch user — \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Batch CRUD
    
    /// Saves or updates a batch record in Core Data.
    func saveBatch(batchID: String, breed: String, eggs: Int32, status: String,
                   temperature: Double, humidity: Double, turnerStatus: String,
                   progress: Double) {
        let request: NSFetchRequest<CDBatch> = CDBatch.fetchRequest()
        request.predicate = NSPredicate(format: "batchID == %@", batchID)
        
        do {
            let existing = try context.fetch(request)
            let batch = existing.first ?? CDBatch(context: context)
            batch.batchID = batchID
            batch.breed = breed
            batch.eggs = eggs
            batch.status = status
            batch.temperature = temperature
            batch.humidity = humidity
            batch.turnerStatus = turnerStatus
            batch.progress = progress
            batch.syncedAt = Date()
            saveContext()
        } catch {
            print("CoreDataManager: Failed to save batch — \(error.localizedDescription)")
        }
    }
    
    /// Fetches all locally stored batches.
    func fetchAllBatches() -> [CDBatch] {
        let request: NSFetchRequest<CDBatch> = CDBatch.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "syncedAt", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("CoreDataManager: Failed to fetch batches — \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Notification CRUD
    
    /// Saves a notification to Core Data for offline access.
    func saveNotification(id: String, type: String, title: String, message: String,
                          timestamp: Date, timeLabel: String, isRead: Bool = false, role: String) {
        let request: NSFetchRequest<CDNotification> = CDNotification.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let existing = try context.fetch(request)
            let notification = existing.first ?? CDNotification(context: context)
            notification.id = id
            notification.type = type
            notification.title = title
            notification.message = message
            notification.timestamp = timestamp
            notification.timeLabel = timeLabel
            notification.isRead = isRead
            notification.role = role
            saveContext()
        } catch {
            print("CoreDataManager: Failed to save notification — \(error.localizedDescription)")
        }
    }
    
    /// Fetches notifications for a specific role, ordered by most recent.
    func fetchNotifications(forRole role: String) -> [CDNotification] {
        let request: NSFetchRequest<CDNotification> = CDNotification.fetchRequest()
        request.predicate = NSPredicate(format: "role == %@", role)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("CoreDataManager: Failed to fetch notifications — \(error.localizedDescription)")
            return []
        }
    }
    
    /// Marks a notification as read.
    func markNotificationAsRead(id: String) {
        let request: NSFetchRequest<CDNotification> = CDNotification.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            if let notification = try context.fetch(request).first {
                notification.isRead = true
                saveContext()
            }
        } catch {
            print("CoreDataManager: Failed to mark notification as read — \(error.localizedDescription)")
        }
    }
    
    /// Returns the count of unread notifications for a role.
    func unreadNotificationCount(forRole role: String) -> Int {
        let request: NSFetchRequest<CDNotification> = CDNotification.fetchRequest()
        request.predicate = NSPredicate(format: "role == %@ AND isRead == NO", role)
        
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
    // MARK: - Observation CRUD
    
    /// Saves a supervisor observation to Core Data.
    func saveObservation(id: String, batchID: String, category: String, note: String,
                         authorName: String, authorRole: String, timeLabel: String, photos: String) {
        let request: NSFetchRequest<CDObservation> = CDObservation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let existing = try context.fetch(request)
            let observation = existing.first ?? CDObservation(context: context)
            observation.id = id
            observation.batchID = batchID
            observation.category = category
            observation.note = note
            observation.authorName = authorName
            observation.authorRole = authorRole
            observation.timeLabel = timeLabel
            observation.photos = photos
            saveContext()
        } catch {
            print("CoreDataManager: Failed to save observation — \(error.localizedDescription)")
        }
    }
    
    /// Fetches observations for a specific batch.
    func fetchObservations(forBatch batchID: String) -> [CDObservation] {
        let request: NSFetchRequest<CDObservation> = CDObservation.fetchRequest()
        request.predicate = NSPredicate(format: "batchID == %@", batchID)
        request.sortDescriptors = [NSSortDescriptor(key: "timeLabel", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("CoreDataManager: Failed to fetch observations — \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Schedule CRUD
    
    /// Saves a scheduled batch to Core Data.
    func saveSchedule(id: String, batchID: String, breed: String, eggs: Int32,
                      time: String, timeOfDay: String, dateLabel: String, status: String) {
        let request: NSFetchRequest<CDSchedule> = CDSchedule.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let existing = try context.fetch(request)
            let schedule = existing.first ?? CDSchedule(context: context)
            schedule.id = id
            schedule.batchID = batchID
            schedule.breed = breed
            schedule.eggs = eggs
            schedule.time = time
            schedule.timeOfDay = timeOfDay
            schedule.dateLabel = dateLabel
            schedule.status = status
            saveContext()
        } catch {
            print("CoreDataManager: Failed to save schedule — \(error.localizedDescription)")
        }
    }
    
    /// Fetches all scheduled batches.
    func fetchAllSchedules() -> [CDSchedule] {
        let request: NSFetchRequest<CDSchedule> = CDSchedule.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateLabel", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("CoreDataManager: Failed to fetch schedules — \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Bulk Delete
    
    /// Deletes all data for a specific entity.
    func deleteAll<T: NSManagedObject>(_ entityType: T.Type) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entityType))
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            saveContext()
        } catch {
            print("CoreDataManager: Failed to delete all \(entityType) — \(error.localizedDescription)")
        }
    }
}
