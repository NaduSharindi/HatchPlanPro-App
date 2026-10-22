import SwiftUI

struct SupervisorHomeView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @StateObject private var viewModel = SupervisorDashboardViewModel()
    @State private var syncMessage = "Ready"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // MARK: - Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good Morning, \(viewModel.fullName)")
                                .font(.title2.bold())
                                .foregroundColor(.hatchGreen)
                            Text("Meegoda Hatchery")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 12) {
                            NavigationLink(destination: SupervisorNotificationsView()) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.hatchGreen)
                                        .padding(10)
                                        .background(Circle().fill(Color.hatchGreenSoft))

                                    if session.unreadSupervisorNotifCount > 0 {
                                        Circle()
                                            .fill(Color.hatchOrange)
                                            .frame(width: 10, height: 10)
                                            .offset(x: 2, y: -2)
                                    }
                                }
                            }
                            .accessibilityLabel("Notifications")
                            .accessibilityValue(session.unreadSupervisorNotifCount > 0 ? "\(session.unreadSupervisorNotifCount) unread" : "No unread notifications")

                            NavigationLink(destination: SupervisorProfileView()) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.hatchGreen)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Today's Target
                    VStack(spacing: 16) {
                        VStack(spacing: 10) {
                            Text("TODAY'S TARGET")
                                .font(.caption.weight(.bold))
                                .kerning(1.1)
                                .foregroundColor(.secondary)
                            ZStack {
                                Circle()
                                    .stroke(Color.hatchOrange.opacity(0.2), lineWidth: 16)
                                Circle()
                                    .trim(from: 0, to: 0.75)
                                    .stroke(Color.hatchOrange, lineWidth: 16)
                                    .rotationEffect(.degrees(-90))
                                VStack(spacing: 4) {
                                    Text("75%")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.hatchGreen)
                                }
                            }
                            .frame(height: 140)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Production Velocity")
                                .font(.headline)
                                .foregroundColor(.hatchGreen)
                            Text("Your hatchery is performing 8% above the weekly average. Temperature stability in Hall B remains optimal.")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("LIVE COUNT")
                                        .font(.caption2.weight(.bold))
                                        .kerning(0.8)
                                    Text("12,480")
                                        .font(.title3.bold())
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.hatchGreenSoft))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("INCUBATING")
                                        .font(.caption2.weight(.bold))
                                        .kerning(0.8)
                                    HStack(spacing: 4) {
                                        Text("4,200")
                                            .font(.title3.bold())
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.hatchGreen)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.hatchOrangeSoft))
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                    }
                    .supervisorCard()
                    .padding(.horizontal, 16)

                    // MARK: - Environmental Stats
                    HStack(spacing: 12) {
                        envStat(title: "AMBIENT TEMP", value: "99.5°F", icon: "thermometer.medium")
                        envStat(title: "HUMIDITY", value: "54%", icon: "drop.fill")
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Upcoming Hatches
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Upcoming Hatches")
                                .font(.headline)
                                .foregroundColor(.hatchGreen)
                            Spacer()
                            NavigationLink(destination: SupervisorScheduleView()) {
                                Text("View Schedule")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.hatchGreen)
                            }
                        }

                        VStack(spacing: 12) {
                            upcomingHatchCard(id: "Batch ID: B87-802", time: "08:45 AM", tag: "CRITICAL", tagColor: Color(hex: "#FFA500"))
                            upcomingHatchCard(id: "Batch ID: B41-445", time: "11:30 AM", tag: nil)
                            upcomingHatchCard(id: "Batch ID: B04-118", time: "02:15 PM", tag: nil)
                            upcomingHatchCard(id: "Batch ID: B09-882", time: "04:00 PM", tag: nil)
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 16)

                    if session.hasTodaySchedule {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("TODAY'S WIDGET")
                                    .font(.caption.weight(.bold))
                                    .kerning(1)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Live schedule")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(.hatchGreen)
                            }

                            ForEach(session.todayScheduledBatches.prefix(2)) { batch in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(batch.batchID)
                                            .font(.headline)
                                            .foregroundColor(.hatchGreen)
                                        Text("\(batch.time) \(batch.timeOfDay) • \(batch.breed)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(batch.status.isEmpty ? "SCHEDULED" : batch.status)
                                        .font(.caption2.weight(.bold))
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(batch.statusColor))
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white))
                            }
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 16)
                    }

                    // MARK: - Facility Health
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Facility Health")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("All sensors reporting optimal ranges across 12 zones.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Button(action: {}) {
                            Text("Check Sensors")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.hatchGreen)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.hatchGreen))
                    .padding(.horizontal, 16)

                    // MARK: - Yield Projection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.hatchGreen)
                            Text("Yield Projection")
                                .font(.headline)
                                .foregroundColor(.hatchGreen)
                            Spacer()
                        }
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PREDICTED YIELD").font(.caption2.weight(.bold)).kerning(0.8)
                                ProgressView(value: viewModel.yieldPrediction)
                                    .tint(.hatchGreen)
                            }
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(Int(viewModel.yieldPrediction * 100))% OVERALL").font(.caption2.weight(.bold)).kerning(0.8).foregroundColor(.hatchGreen)
                            }
                        }
                    }
                    .supervisorCard()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.hatchSurface.ignoresSafeArea())
            .navigationTitle("HatchPlan Pro")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottomTrailing) {
                NavigationLink(destination: ScannerIntroView()) {
                    ZStack {
                        Circle()
                            .fill(Color.hatchGreen)
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.hatchGreen.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .onAppear {
                viewModel.loadData(from: session)
            }
        }
    }

    private func envStat(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption2.weight(.bold))
                .kerning(0.8)
                .foregroundColor(.secondary)
            HStack {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.hatchGreen)
                Spacer()
                Image(systemName: icon)
                    .foregroundColor(.hatchGreen)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func upcomingHatchCard(id: String, time: String, tag: String?, tagColor: Color = .hatchOrange) -> some View {
        HStack(spacing: 12) {
            if let tag = tag {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(tagColor)
                    .padding(8)
                    .background(Circle().fill(tagColor.opacity(0.15)))
            } else {
                Image(systemName: "calendar")
                .foregroundColor(.hatchGreen)
                .padding(8)
                .background(Circle().fill(Color.hatchGreenSoft))
            }

            VStack(alignment: .leading, spacing: 2) {
                if let tag = tag {
                    Text(tag)
                        .font(.caption2.weight(.bold))
                        .kerning(0.8)
                        .foregroundColor(tagColor)
                }
                Text(time)
                    .font(.caption.weight(.semibold))
                Text(id)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: "#FAFAFA")))
    }
}
