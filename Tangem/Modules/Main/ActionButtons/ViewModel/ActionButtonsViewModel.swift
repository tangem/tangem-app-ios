//
//  ActionButtonsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsViewModel: ObservableObject {
    @Published private(set) var actionButtonViewModels: [ActionButtonViewModel]

    init(actionButtonFactory: some ActionButtonsFactory) {
        actionButtonViewModels = actionButtonFactory.makeActionButtonViewModels()
    }

    func fetchData() async {
        async let _ = fetchSwapData()
        async let _ = fetchBuyData()
        async let _ = fetchSellData()
    }
}

// MARK: - Buy

private extension ActionButtonsViewModel {
    private var buyActionButtonViewModel: ActionButtonViewModel? {
        actionButtonViewModels.first { $0.model == .buy }
    }

    private func fetchBuyData() async {
        // [REDACTED_INFO]
    }
}

// MARK: - Swap

private extension ActionButtonsViewModel {
    var swapActionButtonViewModel: ActionButtonViewModel? {
        actionButtonViewModels.first { $0.model == .swap }
    }

    func fetchSwapData() async {
        // [REDACTED_INFO]
    }
}

// MARK: - Sell

private extension ActionButtonsViewModel {
    private var sellActionButtonViewModel: ActionButtonViewModel? {
        actionButtonViewModels.first { $0.model == .sell }
    }

    func fetchSellData() async {
        // [REDACTED_INFO]
    }
}
