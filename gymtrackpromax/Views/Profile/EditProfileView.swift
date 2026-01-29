//
//  EditProfileView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData
import PhotosUI

/// Form-based view for editing user profile information
struct EditProfileView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let user: User

    // MARK: - State

    @State private var name: String = ""
    @State private var experienceLevel: ExperienceLevel = .beginner
    @State private var fitnessGoal: FitnessGoal = .buildMuscle
    @State private var isSaving: Bool = false
    @State private var showingValidationAlert: Bool = false
    @State private var validationMessage: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var profileImageData: Data?

    // MARK: - Computed Properties

    private var hasChanges: Bool {
        name != user.name ||
        experienceLevel != user.experienceLevel ||
        fitnessGoal != user.fitnessGoal ||
        profileImageData != user.profileImageData
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.section) {
                        // Avatar Section
                        avatarSection

                        // Form Fields
                        formSection

                        // Save Button
                        saveButton

                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(.top, AppSpacing.standard)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }
                    .foregroundStyle(Color.gymTextMuted)
                }
            }
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                loadCurrentValues()
            }
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: AppSpacing.component) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack {
                    if let profileImage = profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gymPrimary)
                            .frame(width: 100, height: 100)

                        Text(userInitial)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(Color.gymText)
                    }

                    // Camera overlay
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundStyle(Color.white)
                        )
                        .opacity(0.7)
                }
            }
            .buttonStyle(.plain)
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    await loadImage(from: newItem)
                }
            }

            Text("Tap to change photo")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.standard)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Profile photo. Tap to change")
    }

    // MARK: - Load Image

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                // Compress image to reduce storage size
                if let uiImage = UIImage(data: data) {
                    let resizedImage = resizeImage(uiImage, maxSize: 300)
                    if let compressedData = resizedImage.jpegData(compressionQuality: 0.8) {
                        await MainActor.run {
                            profileImageData = compressedData
                            profileImage = Image(uiImage: resizedImage)
                        }
                    }
                }
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }

    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)

        if ratio >= 1 {
            return image
        }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: AppSpacing.component) {
            // Name Field
            formGroup(title: "Name") {
                TextField("Enter your name", text: $name)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .foregroundStyle(Color.gymText)
                    .padding(AppSpacing.component)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.input)
                            .fill(Color.gymCardHover)
                    )
                    .accessibilityLabel("Name text field")
            }

            // Experience Level
            formGroup(title: "Experience Level") {
                VStack(spacing: AppSpacing.small) {
                    ForEach(ExperienceLevel.allCases, id: \.rawValue) { level in
                        experienceLevelOption(level)
                    }
                }
            }

            // Fitness Goal
            formGroup(title: "Fitness Goal") {
                VStack(spacing: AppSpacing.small) {
                    ForEach(FitnessGoal.allCases, id: \.rawValue) { goal in
                        fitnessGoalOption(goal)
                    }
                }
            }
        }
    }

    // MARK: - Form Group

    private func formGroup(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.gymText)

            content()
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Experience Level Option

    private func experienceLevelOption(_ level: ExperienceLevel) -> some View {
        let isSelected = experienceLevel == level

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            experienceLevel = level
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(level.displayName)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(Color.gymText)

                    Text(level.description)
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.gymPrimary)
                        .font(.title3)
                }
            }
            .padding(AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(isSelected ? Color.gymPrimary.opacity(0.15) : Color.gymCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .strokeBorder(isSelected ? Color.gymPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(level.displayName), \(level.description)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Fitness Goal Option

    private func fitnessGoalOption(_ goal: FitnessGoal) -> some View {
        let isSelected = fitnessGoal == goal

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            fitnessGoal = goal
        } label: {
            HStack(spacing: AppSpacing.component) {
                Image(systemName: goal.iconName)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.gymPrimary : Color.gymTextMuted)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(goal.displayName)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(Color.gymText)

                    Text(goal.description)
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.gymPrimary)
                        .font(.title3)
                }
            }
            .padding(AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(isSelected ? Color.gymPrimary.opacity(0.15) : Color.gymCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .strokeBorder(isSelected ? Color.gymPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(goal.displayName), \(goal.description)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            saveChanges()
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(Color.gymText)
                        .scaleEffect(0.9)
                } else {
                    Text("Save Changes")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.button)
                    .fill(hasChanges && isValid ? Color.gymPrimary : Color.gymCardHover)
            )
            .foregroundStyle(hasChanges && isValid ? Color.gymText : Color.gymTextMuted)
        }
        .disabled(!hasChanges || !isValid || isSaving)
        .padding(.horizontal, AppSpacing.standard)
        .accessibilityLabel("Save changes")
        .accessibilityHint(hasChanges ? "Double tap to save your profile changes" : "No changes to save")
    }

    // MARK: - Helper Functions

    private var userInitial: String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmedName.prefix(1)).uppercased()
    }

    private func loadCurrentValues() {
        name = user.name
        experienceLevel = user.experienceLevel
        fitnessGoal = user.fitnessGoal
        profileImageData = user.profileImageData

        // Load existing profile image
        if let imageData = user.profileImageData,
           let uiImage = UIImage(data: imageData) {
            profileImage = Image(uiImage: uiImage)
        }
    }

    private func saveChanges() {
        // Validate
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationMessage = "Please enter your name"
            showingValidationAlert = true
            return
        }

        isSaving = true

        // Update user
        user.name = trimmedName
        user.experienceLevel = experienceLevel
        user.fitnessGoal = fitnessGoal
        user.profileImageData = profileImageData

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            validationMessage = "Failed to save changes: \(error.localizedDescription)"
            showingValidationAlert = true
        }

        isSaving = false
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, configurations: config)

    let user = User(
        name: "John Doe",
        weightUnit: .kg,
        experienceLevel: .intermediate,
        fitnessGoal: .buildMuscle
    )
    container.mainContext.insert(user)

    return EditProfileView(user: user)
        .modelContainer(container)
}
