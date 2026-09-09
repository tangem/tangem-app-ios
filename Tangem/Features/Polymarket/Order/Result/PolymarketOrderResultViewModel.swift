//
//  PolymarketOrderResultViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class PolymarketOrderResultViewModel: Identifiable {
    private weak var coordinator: PolymarketOrderResultRoutable?

    init(coordinator: PolymarketOrderResultRoutable?) {
        self.coordinator = coordinator
    }

    // MARK: - View actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .toMainTapped:
            coordinator?.closeOrder()
        }
    }
}

// MARK: - ViewAction

extension PolymarketOrderResultViewModel {
    enum ViewAction {
        case toMainTapped
    }
}
