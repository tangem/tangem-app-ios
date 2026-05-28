//
//  RatingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUIUtils

@MainActor
final class RatingViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Typealiases

    typealias Rating = RatingModel.Rating

    // MARK: - Properties

    private let model: RatingModel

    var displayRating: Int {
        switch state {
        case .rated(let rating), .submitted(let rating):
            return rating
        default:
            return selectedRating?.rawValue ?? 0
        }
    }

    var isVisible: Bool {
        switch state {
        case .loading:
            return false
        case .unrated, .rated, .submitting, .submitted:
            return true
        }
    }

    // MARK: - Publishers

    @Published private(set) var state: State = .loading
    @Published private(set) var selectedRating: Rating?

    // MARK: - Init

    nonisolated init(model: RatingModel) {
        self.model = model
    }

    // MARK: - Public methods

    func load() async {
        guard state == .loading else { return }

        async let minimumDelay: () = Task.sleep(for: .milliseconds(300))
        let existingRating = try? await model.checkExisting()
        _ = try? await minimumDelay

        guard let existingRating else {
            return state = .unrated
        }
        state = .rated(existingRating)
    }

    func submitThrowing(rating: Rating, feedback: String?) async throws {
        guard state == .unrated else { return }

        state = .submitting

        do {
            let result = try await model.submit(rating, feedback: feedback)
            switch result {
            case .success:
                state = .submitted(rating.rawValue)
            case .alreadyRated(let existingRating):
                state = .rated(existingRating)
            }
        } catch {
            state = .unrated
            throw error
        }
    }

    func onRatingSelected(_ rating: Rating) {
        guard state == .unrated else { return }
        selectedRating = rating
        showFeedbackPopup(rating: rating)
    }

    func resetSelection() {
        selectedRating = nil
    }

    // MARK: - Private

    private func showFeedbackPopup(rating: Rating) {
        let feedbackViewModel = RatingFeedbackBottomSheetViewModel(
            rating: rating,
            onSubmit: { [weak self] rating, feedback in
                try await self?.submitThrowing(rating: rating, feedback: feedback)
            },
            onDismiss: { [weak self] in
                self?.floatingSheetPresenter.removeActiveSheet()
                self?.resetSelection()
            }
        )

        floatingSheetPresenter.enqueue(sheet: feedbackViewModel)
    }
}

// MARK: - Nested types

extension RatingViewModel {
    enum State: Equatable {
        case loading
        case unrated
        case rated(Int)
        case submitting
        case submitted(Int)
    }
}
