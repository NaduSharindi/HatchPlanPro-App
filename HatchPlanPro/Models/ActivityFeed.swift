//
//  ActivityFeed.swift
//  HatchPlanPro
//
//  Notifications are derived from the batch lifecycle itself, so every device
//  shows the same history and nothing extra has to be synced.
//

import Foundation
import SwiftUI

enum ActivityKind: String {
    case submitted, approved, rejected, executed, transferDue, hatchDue, closed, underperformed

    var label: String {
        switch self {
        case .submitted: return "APPROVAL REQUEST"
        case .approved: return "APPROVAL UPDATE"
        case .rejected: return "ACTION REQUIRED"
        case .executed: return "BATCH SET"
        case .transferDue: return "TRANSFER DUE"
        case .hatchDue: return "CRITICAL ALERT"
        case .closed: return "HATCH REPORT"
        case .underperformed: return "PERFORMANCE ALERT"
        }
    }

    var icon: String {
        switch self {
        case .submitted: return "doc.badge.clock.fill"
        case .approved: return "checkmark.seal.fill"
        case .rejected: return "exclamationmark.bubble.fill"
        case .executed: return "play.circle.fill"
        case .transferDue: return "arrow.right.square.fill"
        case .hatchDue: return "exclamationmark.triangle.fill"
        case .closed: return "chart.bar.doc.horizontal.fill"
        case .underperformed: return "chart.line.downtrend.xyaxis"
        }
    }

    var tint: Color {
        switch self {
        case .hatchDue, .transferDue: return Color(hex: "#B78900")
        case .rejected, .underperformed: return Color(hex: "#B3261E")
        default: return .hatchGreen
        }
    }
}

struct ActivityItem: Identifiable, Hashable {
    let id: String
    let planID: String
    let kind: ActivityKind
    let title: String
    let message: String
    let date: Date
    /// True while the item still needs the reader to act (e.g. a pending review).
    let needsAction: Bool
    var isRead = false
}

enum ActivityFeedBuilder {
    static let windowDays = 45

    static func items(for role: HatcheryRole, plans: [HatchPlanRecord], now: Date = Date()) -> [ActivityItem] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -windowDays, to: now) ?? .distantPast
        var items: [ActivityItem] = []

        func add(_ plan: HatchPlanRecord, _ kind: ActivityKind, _ date: Date?, _ title: String, _ message: String, needsAction: Bool = false) {
            guard let date, date <= now, date >= cutoff else { return }
            items.append(ActivityItem(id: "\(plan.id)-\(kind.rawValue)", planID: plan.id, kind: kind,
                                      title: title, message: message, date: date, needsAction: needsAction))
        }

        for plan in plans {
            let customer = plan.customerName.isEmpty ? "" : " for \(plan.customerName)"
            let hatchWarning = plan.hatchDateValue.addingTimeInterval(-86_400)

            switch role {
            case .manager:
                add(plan, .submitted, plan.submittedAt,
                    "Plan Approval Requested",
                    "\(plan.createdBy) submitted \(plan.batchID): \(plan.targetChicks.formatted()) chicks\(customer) at \(plan.site.name).",
                    needsAction: plan.status == .pendingReview)
                if plan.status == .active || plan.status == .completed {
                    add(plan, .executed, plan.executedAt,
                        "Batch \(plan.batchID) Set",
                        "\(plan.requiredEggs.formatted()) eggs are incubating. Hatch due \(plan.hatchDate).")
                }
                if plan.status == .active {
                    add(plan, .hatchDue, hatchWarning,
                        "\(plan.batchID) Hatches Within 24h",
                        "Confirm chick handling and dispatch capacity at \(plan.site.name).")
                }
                if plan.status == .completed, let rate = plan.actualHatchability {
                    let percent = rate.formatted(.percent.precision(.fractionLength(1)))
                    add(plan, .closed, plan.closedAt,
                        "Batch \(plan.batchID) Closed at \(percent)",
                        "\(plan.actualChicks?.formatted() ?? "—") chicks hatched. The performance report is ready.")
                    if let variance = plan.hatchabilityVariance, variance < -0.03 {
                        add(plan, .underperformed, plan.closedAt.map { $0.addingTimeInterval(1) },
                            "\(plan.batchID) Below Standard",
                            "Hatchability was \(abs(variance).formatted(.percent.precision(.fractionLength(1)))) under the breed standard. Review the source certificate and observations.")
                    }
                }

            case .supervisor:
                if plan.status == .rejected {
                    add(plan, .rejected, plan.reviewedAt,
                        "\(plan.batchID) Needs Changes",
                        plan.rejectionReason ?? "The manager requested changes before setting.",
                        needsAction: true)
                }
                if [.approvedReady, .active, .completed].contains(plan.status) {
                    add(plan, .approved, plan.reviewedAt,
                        "Plan for \(plan.batchID) Approved by \(plan.reviewedBy ?? "Manager")",
                        plan.status == .approvedReady ? "Ready to set on \(plan.eggSetDate)." : "Signed and authorised.",
                        needsAction: plan.status == .approvedReady)
                }
                if plan.status == .active {
                    add(plan, .transferDue, plan.transferDate,
                        "Transfer \(plan.batchID) to Hatcher",
                        "Day \(ProductionCalculator.transferDay): move \(plan.setterTrays) setter trays to hatcher baskets.",
                        needsAction: plan.incubationDay(asOf: now) == ProductionCalculator.transferDay)
                    add(plan, .hatchDue, hatchWarning,
                        "24h to Hatch",
                        "Batch \(plan.batchID) is 24 hours from hatching. Ensure \(plan.site.name) staff are ready.",
                        needsAction: true)
                }
                if plan.status == .completed, let rate = plan.actualHatchability {
                    add(plan, .closed, plan.closedAt,
                        "Batch \(plan.batchID) Closed",
                        "Final hatchability \(rate.formatted(.percent.precision(.fractionLength(1)))).")
                }
            }
        }

        return items.sorted { $0.date > $1.date }
    }
}
