//
//  CollectiblesAddFundsSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemUI

@MainActor
final class CollectiblesAddFundsSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - Properties

    private let input: Input
    private weak var routable: (any CollectiblesAddFundsRoutable)?

    private var selectedOption: Option?

    // MARK: - Publishers

    @Published private(set) var options: [Option] = [.swap, .receive]

    // MARK: - Init

    init(input: Input, routable: any CollectiblesAddFundsRoutable) {
        self.input = input
        self.routable = routable
    }

    // MARK: - Methods

    func select(_ option: Option) {
        guard selectedOption == nil else { return }

        selectedOption = option

        switch option {
        case .swap:
            routable?.openSwap(parameters: input.swapParameters)
        case .receive:
            routable?.openReceive(address: input.address, tokenItem: input.tokenItem)
        }
    }

    func close() {
        routable?.closeAddFunds()
    }
}

// MARK: - Nested types

extension CollectiblesAddFundsSheetViewModel {
    struct Input {
        let address: String
        let tokenItem: TokenItem
        let swapParameters: PredefinedSwapParameters
    }

    enum Option: Identifiable {
        case swap
        case receive

        var id: Self { self }
    }
}
