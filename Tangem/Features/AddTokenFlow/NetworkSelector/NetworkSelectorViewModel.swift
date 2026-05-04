//
//  NetworkSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

final class NetworkSelectorViewModel: FloatingSheetContentViewModel {
    private(set) var itemViewModels: [NetworkSelectorItemViewModel] = []

    private let tokenItems: [TokenItem]
    private let isTokenAdded: (TokenItem) -> Bool
    private let onSelectNetwork: (TokenItem) -> Void

    init(
        tokenItems: [TokenItem],
        isTokenAdded: @escaping (TokenItem) -> Bool,
        onSelectNetwork: @escaping (TokenItem) -> Void
    ) {
        self.tokenItems = tokenItems
        self.isTokenAdded = isTokenAdded
        self.onSelectNetwork = onSelectNetwork

        itemViewModels = tokenItems.map { [weak self] tokenItem in
            NetworkSelectorItemViewModel(
                tokenItem: tokenItem,
                isReadonly: isTokenAdded(tokenItem),
                onTap: { [weak self] in
                    self?.handleNetworkSelection(tokenItem)
                }
            )
        }
    }

    private func handleNetworkSelection(_ tokenItem: TokenItem) {
        guard !isTokenAdded(tokenItem) else { return }
        onSelectNetwork(tokenItem)
    }
}
