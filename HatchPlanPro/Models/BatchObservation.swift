//
//  BatchObservation.swift
//  HatchPlanPro
//
//  A supervisor's floor observation on a batch, with optional photos.
//

import Foundation

struct BatchObservation: Identifiable, Hashable {
    static let maxPhotos = 4

    var id: String = UUID().uuidString
    var planID: String
    var category: ObservationCategory
    var note: String
    var authorName: String
    var authorRole: String
    var authorUID: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    /// JPEG data, already downscaled to fit Firestore's document limit.
    var photos: [Data] = []

    var wasEdited: Bool { updatedAt.timeIntervalSince(createdAt) > 60 }
}
