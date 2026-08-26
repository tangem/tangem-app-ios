//
//  RatingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemUIUtils

@MainActor
final class RatingViewModel: ObservableObject {
    // MARK: - Dependencies

    private weak var feedbackPresenter: (any RatingFeedbackPresenter)?

    // MARK: - Typealiases

    typealias Rating = RatingModel.Rating

    // MARK: - Properties

    private let model: RatingModel
    private var loadTask: Task<Void, Never>?

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

    var isCardVisiblePublisher: AnyPublisher<Bool, Never> {
        $state
            .map { state in
                switch state {
                case .unrated:
                    return true
                case .loading, .submitting, .rated, .submitted:
                    return false
                }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    // MARK: - Publishers

    @Published private(set) var state: State = .loading
    @Published private(set) var selectedRating: Rating?

    // MARK: - Init

    init(model: RatingModel, feedbackPresenter: any RatingFeedbackPresenter) {
        self.model = model
        self.feedbackPresenter = feedbackPresenter
        loadTask = Task { [weak self] in await self?.load() }
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Public methods

    private func load() async {
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
        guard state == .unrated, selectedRating == nil else { return }
        selectedRating = rating

        // Give the star fill a beat to finish before the feedback sheet rises and covers it.
        Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(350))
            } catch {
                return
            }
            self?.presentFeedback(rating: rating)
        }
    }

    func resetSelection() {
        selectedRating = nil
    }

    // MARK: - Private

    private func presentFeedback(rating: Rating) {
        // Only an open (unrated) rating can present feedback — never when a rating is already set or a submit is in flight.
        guard state == .unrated else { return }

        let feedbackViewModel = RatingFeedbackBottomSheetViewModel(
            rating: rating,
            onSubmit: { [weak self] rating, feedback in
                try await self?.submitThrowing(rating: rating, feedback: feedback)
            },
            onDismiss: { [weak self] in
                guard let self else { return }
                feedbackPresenter?.dismiss()
                resetSelection()
            }
        )

        feedbackPresenter?.present(feedbackViewModel)
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
