//
//  EarnDetailViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
final class EarnDetailViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var mostlyUsedViewModels: [EarnTokenItemViewModel] = []

    // [REDACTED_TODO_COMMENT]
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
    }

    // MARK: - Private Implementation

    private func setupMostlyUsedViewModels(from tokens: [EarnTokenModel]) {
        mostlyUsedViewModels = tokens.map { token in
            EarnTokenItemViewModel(token: token) { [weak self] in
                self?.coordinator?.openEarnTokenDetails(for: token)
            }
        }
    }
}

// MARK: - View Action

extension EarnDetailViewModel {
    func handleViewAction(_ viewAction: ViewAction) {
        switch viewAction {
        case .back:
            coordinator?.dismiss()
        case .networksFilterTap:
            // [REDACTED_TODO_COMMENT]
            break
        case .typesFilterTap:
            // [REDACTED_TODO_COMMENT]
            break
        }
    }

    enum ViewAction {
        case back
        case networksFilterTap
        case typesFilterTap
    }
}
