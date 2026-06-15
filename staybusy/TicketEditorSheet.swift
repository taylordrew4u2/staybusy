//
//  TicketEditorSheet.swift
//  staybusy
//
//  Standalone sheet to add or edit a single ticket attached to a block,
//  without entering the full block editor. Surfaces from BlockDetailView
//  so the flow for capturing a confirmation code while you're holding
//  the phone in line at a gate is: tap the block → "Add ticket" → type
//  the code → save. Three taps, no scrolling, no other fields in the
//  way.
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit
import UniformTypeIdentifiers

struct TicketEditorSheet: View {
    let block: Block
    let editing: Ticket?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name: String = ""
    @State private var confirmationCode: String = ""
    @State private var seat: String = ""
    @State private var gate: String = ""
    @State private var holderName: String = ""
    @State private var didHydrate: Bool = false
    @State private var showingDeleteConfirm: Bool = false

    // OCR state
    @State private var photoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingFilesPicker = false
    @State private var isScanning = false
    @State private var scanFeedback: String?

    @FocusState private var codeFocused: Bool

    private var canSave: Bool {
        !draft.isEmpty
    }

    private var draft: TicketDraft {
        TicketDraft(
            name: name,
            confirmationCode: confirmationCode,
            seat: seat,
            gate: gate,
            holderName: holderName
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    scanSection

                    field("LABEL") {
                        TextField("e.g. Boarding pass", text: $name)
                            .textInputAutocapitalization(.sentences)
                    }

                    field("CONFIRMATION CODE") {
                        TextField("e.g. DL-AB12CD", text: $confirmationCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .focused($codeFocused)
                    }

                    HStack(spacing: Theme.Spacing.m) {
                        field("SEAT") {
                            TextField("12A", text: $seat)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                        }
                        field("GATE") {
                            TextField("B23", text: $gate)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                        }
                    }

                    field("HOLDER (OPTIONAL)") {
                        TextField("Name on ticket", text: $holderName)
                            .textInputAutocapitalization(.words)
                    }

                    if editing != nil {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            HStack(spacing: Theme.Spacing.s) {
                                Image(systemName: "trash.fill")
                                Text("Delete ticket")
                                    .font(Theme.Font.title)
                            }
                            .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget)
                            .padding(.vertical, Theme.Spacing.s)
                            .background(
                                Theme.Color.accent.opacity(0.18),
                                in: RoundedRectangle(cornerRadius: Theme.Radius.medium)
                            )
                            .foregroundStyle(Theme.Color.accent)
                        }
                        .buttonStyle(.pressable)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.Color.background)
            .navigationTitle(editing == nil ? "New Ticket" : "Edit Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .font(Theme.Font.title)
                        .foregroundStyle(canSave ? Theme.Color.accent : Theme.Color.textTertiary)
                        .disabled(!canSave)
                }
            }
            .toolbarBackground(Theme.Color.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .appTheme()
        .tint(Theme.Color.accent)
        .onAppear(perform: hydrate)
        .photosPicker(
            isPresented: photosPickerBinding,
            selection: $photoItem,
            matching: .images
        )
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await scan(from: item) }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                showingCamera = false
                guard let image else { return }
                Task { await scanAndAttach(image: image, sourceExtension: "jpg") }
            }
            .ignoresSafeArea()
        }
        .fileImporter(
            isPresented: $showingFilesPicker,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                Task { await scanAndAttach(fileURL: url) }
            case .failure:
                scanFeedback = "Couldn't open that file."
            }
        }
        .confirmationDialog(
            "Delete this ticket?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: - Scan UI

    @ViewBuilder
    private var scanSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(alignment: .top, spacing: Theme.Spacing.m) {
                Image(systemName: "doc.text.viewfinder")
                    .font(Theme.Font.titleLarge)
                    .foregroundStyle(Theme.Color.accent)
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Scan or upload a boarding pass")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("StayBusy reads the confirmation code, seat, gate, and flight from a photo or PDF, and keeps the file with the block.")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: Theme.Spacing.s) {
                scanButton(
                    title: "Camera",
                    symbol: "camera.fill",
                    action: { showingCamera = true }
                )
                scanButton(
                    title: "Photos",
                    symbol: "photo.on.rectangle.angled",
                    action: { showingPhotosPicker = true }
                )
                scanButton(
                    title: "Files",
                    symbol: "doc.fill",
                    action: { showingFilesPicker = true }
                )
            }

            if isScanning {
                HStack(spacing: Theme.Spacing.s) {
                    ProgressView().scaleEffect(0.8).tint(Theme.Color.accent)
                    Text("Reading ticket\u{2026}")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            } else if let feedback = scanFeedback {
                Text(feedback)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Theme.Spacing.m)
        .background(
            Theme.Color.surface,
            in: RoundedRectangle(cornerRadius: Theme.Radius.medium)
        )
    }

    private func scanButton(
        title: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: symbol)
                Text(title)
                    .font(Theme.Font.title)
            }
            .foregroundStyle(Theme.Color.accent)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget)
            .padding(.vertical, Theme.Spacing.s)
            .background(
                Theme.Color.accent.opacity(0.12),
                in: RoundedRectangle(cornerRadius: Theme.Radius.small)
            )
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Scan ticket from \(title)")
        .disabled(isScanning)
    }

    // MARK: - Scan handling

    @State private var showingPhotosPicker = false

    private var photosPickerBinding: Binding<Bool> {
        Binding(
            get: { showingPhotosPicker },
            set: { showingPhotosPicker = $0 }
        )
    }

    @MainActor
    private func scan(from item: PhotosPickerItem) async {
        defer { photoItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            scanFeedback = "Couldn't read that image."
            return
        }
        await scanAndAttach(image: image, sourceExtension: "jpg")
    }

    /// Scan an in-memory image. Saves a JPEG copy as a block attachment
    /// so the user can pull the boarding pass back up from detail view
    /// later.
    @MainActor
    private func scanAndAttach(image: UIImage, sourceExtension ext: String) async {
        isScanning = true
        scanFeedback = nil
        attach(image: image, preferredExtension: ext)
        let draft = await TicketScanner.scan(image)
        isScanning = false
        applyScanned(draft)
    }

    /// Scan a file URL — handles PDFs via PDFKit + images. Copies the
    /// original file into the attachment store so the boarding pass
    /// stays readable from BlockDetailView.
    @MainActor
    private func scanAndAttach(fileURL: URL) async {
        isScanning = true
        scanFeedback = nil
        attach(fileURL: fileURL)
        let draft = await TicketScanner.scan(fileURL: fileURL)
        isScanning = false
        applyScanned(draft)
    }

    private func attach(image: UIImage, preferredExtension ext: String) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        let saved = AttachmentStore.attach(
            data: data, extension: ext, to: block, in: context
        )
        guard let saved else { return }
        addAttachment(filename: saved.lastPathComponent)
    }

    private func attach(fileURL: URL) {
        let needsScope = fileURL.startAccessingSecurityScopedResource()
        defer { if needsScope { fileURL.stopAccessingSecurityScopedResource() } }
        guard let saved = AttachmentStore.attach(from: fileURL, to: block, in: context) else { return }
        addAttachment(filename: saved.lastPathComponent)
    }

    private func addAttachment(filename: String) {
        guard !block.attachmentFilenames.contains(filename) else { return }
        block.attachmentFilenames.append(filename)
    }

    /// Merge OCR results into the form. Only fills empty fields so the
    /// user's manual edits aren't overwritten. Reports back what was
    /// filled so the user knows what changed.
    private func applyScanned(_ draft: TicketDraft) {
        var filled: [String] = []
        if name.isEmpty && !draft.name.isEmpty {
            name = draft.name
            filled.append("label")
        }
        if confirmationCode.isEmpty && !draft.confirmationCode.isEmpty {
            confirmationCode = draft.confirmationCode
            filled.append("code")
        }
        if seat.isEmpty && !draft.seat.isEmpty {
            seat = draft.seat
            filled.append("seat")
        }
        if gate.isEmpty && !draft.gate.isEmpty {
            gate = draft.gate
            filled.append("gate")
        }
        if holderName.isEmpty && !draft.holderName.isEmpty {
            holderName = draft.holderName
            filled.append("holder")
        }
        if filled.isEmpty {
            scanFeedback = "Couldn't find ticket fields — try a clearer photo."
        } else {
            scanFeedback = "Filled: \(filled.joined(separator: " · "))"
            Theme.Haptic.blockSaved()
        }
    }

    // MARK: - Lifecycle

    private func hydrate() {
        guard !didHydrate else { return }
        if let t = editing {
            name = t.name
            confirmationCode = t.confirmationCode
            seat = t.seat
            gate = t.gate
            holderName = t.holderName
        }
        didHydrate = true
        if editing == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                codeFocused = true
            }
        }
    }

    private func save() {
        guard canSave else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCode = confirmationCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSeat = seat.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGate = gate.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHolder = holderName
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let t = editing {
            t.name = trimmedName
            t.confirmationCode = trimmedCode
            t.seat = trimmedSeat
            t.gate = trimmedGate
            t.holderName = trimmedHolder
        } else {
            let nextOrder = (block.orderedTickets.map(\.sortOrder).max() ?? -1) + 1
            let ticket = Ticket(
                name: trimmedName,
                confirmationCode: trimmedCode,
                seat: trimmedSeat,
                gate: trimmedGate,
                holderName: trimmedHolder,
                sortOrder: nextOrder
            )
            ticket.block = block
            context.insert(ticket)
        }
        try? context.save()
        Theme.Haptic.blockSaved()
        dismiss()
    }

    private func delete() {
        guard let t = editing else { return }
        context.delete(t)
        try? context.save()
        dismiss()
    }

    // MARK: - Field helper

    @ViewBuilder
    private func field<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(label)
                .font(Theme.Font.caption)
                .tracking(1.2)
                .foregroundStyle(Theme.Color.textTertiary)
            content()
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textPrimary)
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.s)
                .background(
                    Theme.Color.surface,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.small)
                )
        }
    }
}

// MARK: - Camera picker
//
// SwiftUI doesn't ship a native camera picker, so we wrap UIKit's
// UIImagePickerController. Returns the captured UIImage (or nil if the
// user cancelled) to the binding closure.

private struct CameraPicker: UIViewControllerRepresentable {
    let onResult: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera)
            ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onResult: (UIImage?) -> Void

        init(onResult: @escaping (UIImage?) -> Void) {
            self.onResult = onResult
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            onResult(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onResult(nil)
        }
    }
}
