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
    let onCancel: (() -> Void)?

    private let tokenItems: [TokenItem]
    private let isTokenAdded: (TokenItem) -> Bool
    private let onSelectNetwork: (TokenItem) -> Void

    init(
        tokenItems: [TokenItem],
        isTokenAdded: @escaping (TokenItem) -> Bool,
        onSelectNetwork: @escaping (TokenItem) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.tokenItems = tokenItems
        self.isTokenAdded = isTokenAdded
        self.onSelectNetwork = onSelectNetwork
        self.onCancel = onCancel

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

// MARK: - Equatable

extension NetworkSelectorViewModel: Equatable {
    static func == (lhs: NetworkSelectorViewModel, rhs: NetworkSelectorViewModel) -> Bool {
        lhs === rhs
    }
}
