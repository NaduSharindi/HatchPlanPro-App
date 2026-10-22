//
//  SpotlightIndexer.swift
//  HatchPlanPro
//
//  Core Spotlight: makes batches searchable from the iOS search bar and
//  deep-links back into the batch. Controlled by Settings › Siri & Search.
//

import Foundation
import CoreSpotlight
import UniformTypeIdentifiers

enum SpotlightIndexer {
    static let preferenceKey = "siriEnabled"
    static let domain = "com.hatchplanpro.batch"

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: preferenceKey) as? Bool ?? true
    }

    static func index(_ plans: [HatchPlanRecord]) {
        guard isEnabled, CSSearchableIndex.isIndexingAvailable() else { return }
        let items = plans.map { plan -> CSSearchableItem in
            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title = "Batch \(plan.batchID) – \(plan.status.displayName.capitalized)"
            var details = ["\(plan.breed.rawValue) • flock \(plan.flockID)", plan.site.name,
                           "\(plan.targetChicks.formatted()) chicks • hatch \(plan.hatchDate)"]
            if !plan.customerName.isEmpty { details.insert(plan.customerName, at: 1) }
            attributes.contentDescription = details.joined(separator: "\n")
            attributes.keywords = [plan.batchID, plan.flockID, plan.breed.rawValue, plan.site.name, plan.customerName, "hatch", "batch"]
            return CSSearchableItem(uniqueIdentifier: plan.id, domainIdentifier: domain, attributeSet: attributes)
        }
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error { print("SpotlightIndexer: \(error.localizedDescription)") }
        }
    }

    static func removeAll() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domain]) { _ in }
    }
}
