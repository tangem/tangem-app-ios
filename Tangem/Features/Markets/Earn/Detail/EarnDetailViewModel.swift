//
//  EarnDetailViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

@MainActor
final class EarnDetailViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var mostlyUsedViewModels: [EarnTokenItemViewModel] = []
    @Published private(set) var bestOpportunitiesResultState: LoadingResult<[EarnTokenItemViewModel], Error> = .loading

    // [REDACTED_TODO_COMMENT]

    // MARK: - Private Properties

    private weak var coordinator: EarnDetailRoutable?

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_TODO_COMMENT]

    // MARK: - Init

    init(
        mostlyUsedTokens: [EarnTokenModel],
        coordinator: EarnDetailRoutable? = nil
    ) {
        self.coordinator = coordinator
        setupMostlyUsedViewModels(from: mostlyUsedTokens)
        loadBestOpportunities()
    }

    // MARK: - Private Implementation

    private func setupMostlyUsedViewModels(from tokens: [EarnTokenModel]) {
        mostlyUsedViewModels = tokens.map { token in
            EarnTokenItemViewModel(token: token) { [weak self] in
                self?.coordinator?.openEarnTokenDetails(for: token)
            }
        }
    }

    func loadBestOpportunities() {
        // [REDACTED_TODO_COMMENT]
        // 
        bestOpportunitiesResultState = .loading

        // Placeholder: simulate loading
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            // For now, set to error to demonstrate error state
            // In real implementation, this would fetch data and set to .success or .failure
            let error = NSError(
                domain: "EarnDetailViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to load best opportunities"]
            )
            bestOpportunitiesResultState = .failure(error)
        }
    }

    func retryBestOpportunities() {
        loadBestOpportunities()
    }
}

// MARK: - View Action

extension EarnDetailViewModel {
    func handleViewAction(_ viewAction: ViewAction) {
        switch viewAction {
        case .back:
            coordinator?.dismiss()
        case .networksFilterTap:
            coordinator?.openNetworksFilter()
        case .typesFilterTap:
            coordinator?.openTypesFilter()
        }
    }

    enum ViewAction {
        case back
        case networksFilterTap
        case typesFilterTap
    }
}
