//
//  SupervisorObservationEditorView.swift
//  HatchPlanPro
//
//  Created by GitHub Copilot on 2026-05-13.
//

import SwiftUI

struct SupervisorObservationEditorView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @Environment(\.dismiss) private var dismiss

    let batch: ScheduledBatch
    let existingObservation: SupervisorObservation?

    @State private var selectedCategory: ObservationCategory
    @State private var noteText: String
    @State private var attachedPhotos: [String]
    @State private var photoAssetName: String = ""

    init(batch: ScheduledBatch, existingObservation: SupervisorObservation?) {
        self.batch = batch
        self.existingObservation = existingObservation
        _selectedCategory = State(initialValue: existingObservation.flatMap { ObservationCategory(rawValue: $0.category) } ?? .shellQuality)
        _noteText = State(initialValue: existingObservation?.note ?? "")
        _attachedPhotos = State(initialValue: existingObservation?.attachedPhotos ?? [])
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                categoryCard
                detailsCard
                photoCard
                footerCard
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationTitle("Add Observation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    saveObservation()
                }
                .font(.headline)
                .foregroundColor(.secondary)
            }
        }
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("OBSERVATION TYPE")
                .font(.caption.weight(.bold))
                .kerning(1)
                .foregroundColor(Color(hex: "#977A09"))

            WrapChipsView(categories: ObservationCategory.allCases, selectedCategory: $selectedCategory)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DETAILS")
                .font(.caption.weight(.bold))
                .kerning(1)
                .foregroundColor(.secondary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $noteText)
                    .padding(14)
                    .frame(minHeight: 220)
                    .scrollContentBackground(.hidden)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                if noteText.isEmpty {
                    Text("Describe your observation from the industrial floor...")
                        .foregroundColor(Color(hex: "#AAB7C7"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .allowsHitTesting(false)
                }
            }
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color(hex: "#EEF0F3"), lineWidth: 1))
        }
        .padding(.horizontal, 16)
    }

    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Button {
                    if !photoAssetName.isEmpty {
                        attachedPhotos.append(photoAssetName.trimmingCharacters(in: .whitespacesAndNewlines))
                        photoAssetName = ""
                    }
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.hatchGreen)
                        Text("ATTACH PHOTO")
                            .font(.caption.weight(.bold))
                            .kerning(0.8)
                            .foregroundColor(.hatchGreen)
                    }
                    .frame(maxWidth: .infinity, minHeight: 140)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(hex: "#F2F2F4"))
                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color(hex: "#DDDEE2"), style: StrokeStyle(lineWidth: 1, dash: [6])))
                    )
                }
                .buttonStyle(.plain)

                VStack(spacing: 12) {
                    if let firstPhoto = attachedPhotos.first {
                        Image(firstPhoto)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(hex: "#EEF0F3"))
                            .frame(height: 140)
                            .overlay(Image(systemName: "photo.on.rectangle.angled").font(.title2).foregroundColor(.hatchGreen))
                    }
                }
                .frame(maxWidth: .infinity)
            }

            TextField("Enter image asset name to attach", text: $photoAssetName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(hex: "#E8EAEE"), lineWidth: 1))
                .foregroundColor(.hatchGreen)

            if !attachedPhotos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(attachedPhotos, id: \.self) { photoName in
                            ZStack(alignment: .topTrailing) {
                                Image(photoName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                Button {
                                    attachedPhotos.removeAll { $0 == photoName }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .shadow(radius: 2)
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private var footerCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TIMESTAMP")
                    .font(.caption.weight(.bold))
                    .kerning(0.8)
                    .foregroundColor(Color(hex: "#A5B4C5"))
                Text(DateFormatter.observationTimestamp.string(from: Date()))
                    .font(.callout.weight(.semibold))
                    .foregroundColor(.hatchGreen)
            }

            Spacer()

            HStack(spacing: 10) {
                Circle()
                    .fill(Color.hatchGreen)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text("SUPERVISOR ID")
                        .font(.caption.weight(.bold))
                        .kerning(0.8)
                        .foregroundColor(Color(hex: "#A5B4C5"))
                    Text(session.currentUser.fullName.isEmpty ? "HX-992-ALPHA" : "HX-992-ALPHA")
                        .font(.callout.weight(.bold))
                        .foregroundColor(.hatchGreen)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color(hex: "#EEF0F3")))
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private func saveObservation() {
        session.saveObservation(
            for: batch.batchID,
            category: selectedCategory,
            note: noteText,
            attachedPhotos: attachedPhotos,
            editingObservationID: existingObservation?.id
        )
        dismiss()
    }
}

private struct WrapChipsView: View {
    let categories: [ObservationCategory]
    @Binding var selectedCategory: ObservationCategory

    var body: some View {
        let rows = categories.chunked(into: 2)

        VStack(spacing: 10) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 10) {
                    ForEach(rows[rowIndex], id: \.self) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Text(category.rawValue)
                                .font(.body)
                                .foregroundColor(selectedCategory == category ? .white : .hatchGreen)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 14)
                                .background(
                                    Capsule().fill(selectedCategory == category ? category.accentColor : Color(hex: "#E5E5EA"))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

private extension DateFormatter {
    static let observationTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy • HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

#Preview {
    NavigationStack {
        SupervisorObservationEditorView(
            batch: ScheduledBatch(batchID: "#B7-902", breed: "Ross 308", eggs: 12480, time: "08:45", timeOfDay: "AM", dateLabel: "TODAY, OCT 25", status: "CRITICAL", statusColor: Color(hex: "#F4C542")),
            existingObservation: nil
        )
        .environmentObject(AppSessionViewModel())
    }
}
