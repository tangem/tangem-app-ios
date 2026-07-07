//
//  RatingFeedbackBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization

@MainActor
final class RatingFeedbackBottomSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    typealias Rating = RatingModel.Rating
    typealias OnSubmit = (Rating, String?) async throws -> Void

    // MARK: - Properties

    private let rating: Rating
    private let onSubmit: OnSubmit
    private let onDismiss: () -> Void

    private var isDismissed = false

    var isSubmitEnabled: Bool { !isSubmitting }

    // MARK: - Publishers

    @Published var feedbackText: String = ""
    @Published private(set) var isSubmitting: Bool = false

    // MARK: - Init

    init(rating: Rating, onSubmit: @escaping OnSubmit, onDismiss: @escaping () -> Void) {
        self.rating = rating
        self.onSubmit = onSubmit
        self.onDismiss = onDismiss
    }

    // MARK: - Public methods

    func submit() async {
        guard !isSubmitting else { return }

        isSubmitting = true

        // Normalization (trim, empty -> nil) is handled by RatingModel
        let feedback = feedbackText.isEmpty ? nil : feedbackText

        do {
            try await onSubmit(rating, feedback)
            isSubmitting = false
            showSuccessToast()
            dismiss()
        } catch {
            isSubmitting = false
            showErrorToast()
        }
    }

    func dismiss() {
        guard !isDismissed else { return }
        isDismissed = true
        onDismiss()
    }
}

private extension RatingFeedbackBottomSheetViewModel {
    // MARK: - Private logic

    func showSuccessToast() {
        Toast(view: SuccessToast(text: Localization.commonSuccess))
            .present(layout: .top(padding: 20), type: .temporary())
    }

    func showErrorToast() {
        Toast(view: WarningToast(text: Localization.commonSomethingWentWrong))
            .present(layout: .top(padding: 20), type: .temporary())
    }
}
