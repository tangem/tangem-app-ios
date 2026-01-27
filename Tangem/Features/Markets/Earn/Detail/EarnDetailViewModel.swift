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

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_TODO_COMMENT]
    // [REDACTED_TODO_COMMENT]

    // MARK: - Private Properties

    private weak var coordinator: EarnDetailRoutable?

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_TODO_COMMENT]

    // MARK: - Init

    init(
        coordinator: EarnDetailRoutable? = nil
    ) {
        self.coordinator = coordinator
    }
}

// MARK: - View Action

extension EarnDetailViewModel {
    func handleViewAction(_ viewAction: ViewAction) {
        switch viewAction {
        case .back:
            coordinator?.dismiss()
        }
    }

    enum ViewAction {
        case back
    }
}
