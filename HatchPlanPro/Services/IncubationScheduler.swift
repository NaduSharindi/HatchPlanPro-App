//
//  IncubationScheduler.swift
//  HatchPlanPro
//
//  Turns an executed batch into calendar milestones (EventKit) and
//  on-device reminders (UserNotifications) for the 21-day incubation cycle.
//

import Foundation
import EventKit
import UserNotifications

struct IncubationMilestone: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let date: Date
    let day: Int
}

struct ScheduleOutcome: Hashable, Identifiable {
    let id = UUID()
    var calendarEventIDs: [String] = []
    var calendarError: String?
    var remindersScheduled = 0
}

final class IncubationScheduler {
    static let shared = IncubationScheduler()

    private let eventStore = EKEventStore()
    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    /// Milestones for a batch set on `setDate`, at 08:00 on each day.
    func milestones(for plan: HatchPlanRecord, setDate: Date) -> [IncubationMilestone] {
        let calendar = Calendar.current
        func morning(ofDay day: Int) -> Date {
            let date = calendar.date(byAdding: .day, value: day, to: calendar.startOfDay(for: setDate)) ?? setDate
            return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date) ?? date
        }

        let eggs = plan.requiredEggs.formatted()
        return [
            IncubationMilestone(id: "candling", title: "Candling – \(plan.batchID)",
                                detail: "Day 10: candle \(eggs) eggs and remove clears.", date: morning(ofDay: 10), day: 10),
            IncubationMilestone(id: "transfer", title: "Transfer to Hatcher – \(plan.batchID)",
                                detail: "Day \(ProductionCalculator.transferDay): move \(plan.setterTrays) setter trays to hatcher baskets.",
                                date: morning(ofDay: ProductionCalculator.transferDay), day: ProductionCalculator.transferDay),
            IncubationMilestone(id: "hatch", title: "Hatch Day – \(plan.batchID)",
                                detail: "Day \(ProductionCalculator.incubationDays): pull chicks and log actual hatch for \(plan.site.name).",
                                date: morning(ofDay: ProductionCalculator.incubationDays), day: ProductionCalculator.incubationDays)
        ]
    }

    /// Writes milestones to the default calendar and schedules reminders.
    /// Calendar access failure is reported but does not block execution.
    func schedule(_ plan: HatchPlanRecord, setDate: Date,
                  addToCalendar: Bool, addReminders: Bool) async -> ScheduleOutcome {
        var outcome = ScheduleOutcome()
        let milestones = milestones(for: plan, setDate: setDate)

        if addToCalendar {
            do {
                outcome.calendarEventIDs = try await addCalendarEvents(milestones, plan: plan)
            } catch {
                outcome.calendarError = error.localizedDescription
            }
        }

        if addReminders {
            outcome.remindersScheduled = await scheduleReminders(milestones, plan: plan)
        }
        return outcome
    }

    func cancelReminders(for plan: HatchPlanRecord) {
        let ids = ["candling", "transfer", "hatch", "hatch-24h"].map { reminderID($0, plan: plan) }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - EventKit

    private func addCalendarEvents(_ milestones: [IncubationMilestone], plan: HatchPlanRecord) async throws -> [String] {
        let granted = try await eventStore.requestWriteOnlyAccessToEvents()
        guard granted else { throw SchedulerError.calendarDenied }
        guard let calendar = eventStore.defaultCalendarForNewEvents else { throw SchedulerError.noCalendar }

        var identifiers: [String] = []
        for milestone in milestones {
            let event = EKEvent(eventStore: eventStore)
            event.calendar = calendar
            event.title = milestone.title
            event.notes = "\(milestone.detail)\nSite: \(plan.site.name)\nHatchPlan Pro batch \(plan.batchID)"
            event.location = plan.site.name
            event.startDate = milestone.date
            event.endDate = milestone.date.addingTimeInterval(3600)
            event.addAlarm(EKAlarm(relativeOffset: -3600))
            try eventStore.save(event, span: .thisEvent, commit: false)
            if let identifier = event.eventIdentifier {
                identifiers.append(identifier)
            }
        }
        try eventStore.commit()
        return identifiers
    }

    // MARK: - Notifications

    private func scheduleReminders(_ milestones: [IncubationMilestone], plan: HatchPlanRecord) async -> Int {
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return 0
        }

        var reminders = milestones.map { ($0.id, $0.title, $0.detail, $0.date) }
        if let hatch = milestones.first(where: { $0.id == "hatch" }) {
            reminders.append(("hatch-24h", "24h to Hatch",
                              "Batch \(plan.batchID) is 24 hours away from hatching. Ensure \(plan.site.name) staff are ready.",
                              hatch.date.addingTimeInterval(-86_400)))
        }

        var scheduled = 0
        for reminder in reminders where reminder.3 > Date() {
            let content = UNMutableNotificationContent()
            content.title = reminder.1
            content.body = reminder.2
            content.sound = .default
            content.userInfo = ["planID": plan.id]

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.3)
            let request = UNNotificationRequest(
                identifier: reminderID(reminder.0, plan: plan),
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            do {
                try await notificationCenter.add(request)
                scheduled += 1
            } catch {
                print("IncubationScheduler: reminder failed — \(error.localizedDescription)")
            }
        }
        return scheduled
    }

    private func reminderID(_ milestone: String, plan: HatchPlanRecord) -> String {
        "incubation-\(plan.id)-\(milestone)"
    }

    enum SchedulerError: LocalizedError {
        case calendarDenied
        case noCalendar

        var errorDescription: String? {
            switch self {
            case .calendarDenied:
                return "Calendar access was declined. Enable it in Settings › Privacy › Calendars to sync milestones."
            case .noCalendar:
                return "No default calendar is set on this device."
            }
        }
    }
}
