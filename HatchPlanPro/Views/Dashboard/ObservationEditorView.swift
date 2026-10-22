//
//  ObservationEditorView.swift
//  HatchPlanPro
//
//  Add or edit a floor observation with up to four photos.
//

import SwiftUI
import PhotosUI

struct ObservationEditorView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var draft: BatchObservation
    private let isNew: Bool

    @State private var photoItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showCameraUnavailable = false
    @State private var showDeleteConfirm = false
    @State private var previewPhoto: PreviewPhoto?
    @State private var errorMessage: String?
    @FocusState private var noteFocused: Bool

    init(observation: BatchObservation, isNew: Bool) {
        _draft = State(initialValue: observation)
        self.isNew = isNew
    }

    private var remainingSlots: Int { BatchObservation.maxPhotos - draft.photos.count }
    private var canSave: Bool { !draft.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.hatchGreen)
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel("Cancel")
                Spacer()
                Text(isNew ? "Add Observation" : "Edit Observation")
                    .font(.headline.weight(.bold))
                Spacer()
                Button("Done", action: save)
                    .font(.headline)
                    .foregroundColor(canSave ? .hatchGreen : .secondary)
                    .disabled(!canSave)
                    .frame(minWidth: 40)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    categorySection
                    detailsSection
                    photosSection
                    if let errorMessage { AuthErrorBanner(message: errorMessage) }
                    if !isNew {
                        Button(role: .destructive, action: { showDeleteConfirm = true }) {
                            Label("Delete Observation", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.1)))
                        }
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)

            footer
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: photoItems) { _, items in
            guard !items.isEmpty else { return }
            Task {
                for item in items.prefix(remainingSlots) {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data),
                       let compressed = ObservationRepository.compressed(image) {
                        draft.photos.append(compressed)
                    }
                }
                photoItems = []
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                if let compressed = ObservationRepository.compressed(image), remainingSlots > 0 {
                    draft.photos.append(compressed)
                }
            }
            .ignoresSafeArea()
        }
        .sheet(item: $previewPhoto) { photo in
            if let image = UIImage(data: photo.data) {
                Image(uiImage: image).resizable().scaledToFit().padding()
                    .presentationDragIndicator(.visible)
            }
        }
        .alert("Camera Unavailable", isPresented: $showCameraUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Taking photos needs a physical iPhone or iPad. Use Choose from Photos on the Simulator.")
        }
        .confirmationDialog("Delete this observation?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                ObservationRepository.shared.delete(draft)
                dismiss()
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OBSERVATION TYPE").font(.caption.weight(.bold)).tracking(1.2).foregroundColor(.hatchOrange)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(ObservationCategory.allCases, id: \.self) { category in
                    Button(action: { draft.category = category; Haptics.tap() }) {
                        Label(category.rawValue, systemImage: category.icon)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundColor(draft.category == category ? .white : .hatchGreen)
                            .background(Capsule().fill(draft.category == category ? Color.hatchGreen : Color(hex: "#E9E9EE")))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(draft.category == category ? .isSelected : [])
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.white))
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DETAILS").font(.caption.weight(.bold)).tracking(1.2).foregroundColor(.secondary)
            ZStack(alignment: .topLeading) {
                if draft.note.isEmpty {
                    Text("Describe your observation from the industrial floor…")
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                }
                TextEditor(text: $draft.note)
                    .focused($noteFocused)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 140)
                    .accessibilityLabel("Observation details")
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 16).fill(.white))
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ATTACHED PHOTOS (\(draft.photos.count)/\(BatchObservation.maxPhotos))")
                    .font(.caption.weight(.bold)).tracking(1.2).foregroundColor(.secondary)
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                ForEach(Array(draft.photos.enumerated()), id: \.offset) { index, data in
                    if let image = UIImage(data: data) {
                        Button(action: { previewPhoto = PreviewPhoto(data: data) }) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 130)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .topTrailing) {
                            Button(action: { draft.photos.remove(at: index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .black.opacity(0.6))
                            }
                            .padding(6)
                            .accessibilityLabel("Remove photo \(index + 1)")
                        }
                    }
                }

                if remainingSlots > 0 {
                    Button(action: { CameraPicker.isAvailable ? (showCamera = true) : (showCameraUnavailable = true) }) {
                        addTile(icon: "camera.fill", title: "TAKE PHOTO")
                    }
                    .buttonStyle(.plain)

                    PhotosPicker(selection: $photoItems, maxSelectionCount: remainingSlots, matching: .images) {
                        addTile(icon: "photo.on.rectangle.angled", title: "CHOOSE PHOTOS")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func addTile(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2)
            Text(title).font(.caption.weight(.bold)).tracking(1)
        }
        .foregroundColor(.hatchGreen)
        .frame(maxWidth: .infinity)
        .frame(height: 130)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                .foregroundColor(.secondary.opacity(0.5))
        )
    }

    private var footer: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TIMESTAMP").font(.caption2.weight(.bold)).foregroundColor(.secondary)
                Text((isNew ? Date() : draft.updatedAt).formatted(date: .abbreviated, time: .standard))
                    .font(.caption)
            }
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(Color.hatchGreen).frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text("SUPERVISOR").font(.caption2.weight(.bold)).foregroundColor(.secondary)
                    Text(session.currentUser.employeeID.isEmpty ? draft.authorName : session.currentUser.employeeID)
                        .font(.caption.weight(.bold))
                        .foregroundColor(.hatchGreen)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color(hex: "#E9E9EE")))
        }
        .padding(16)
        .background(Color.white)
    }

    private func save() {
        noteFocused = false
        do {
            try session.saveObservation(draft)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct PreviewPhoto: Identifiable {
    let id = UUID()
    let data: Data
}
