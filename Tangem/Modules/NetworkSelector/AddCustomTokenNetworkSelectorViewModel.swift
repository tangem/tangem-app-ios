//
//  AddCustomTokenNetworkSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BlockchainSdk

final class AddCustomTokenNetworkSelectorViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var itemViewModels: [AddCustomTokenNetworkSelectorItemViewModel] = []

    // MARK: - Dependencies

    private unowned let coordinator: AddCustomTokenNetworkSelectorRoutable

    init(selectedBlockchain: Blockchain, blockchains: [Blockchain], coordinator: AddCustomTokenNetworkSelectorRoutable) {
        self.coordinator = coordinator
        itemViewModels = blockchains.map { blockchain in
            AddCustomTokenNetworkSelectorItemViewModel(
                networkId: blockchain.networkId,
                iconName: blockchain.iconNameFilled,
                networkName: blockchain.displayName,
                currencySymbol: blockchain.currencySymbol,
                isSelected: blockchain == selectedBlockchain
            ) { [weak self] in
                self?.didTapNetwork(blockchain)
            }
        }
    }

    func didTapNetwork(_ blockchain: Blockchain) {
        for itemViewModel in itemViewModels {
            itemViewModel.isSelected = (blockchain.networkId == itemViewModel.networkId)
        }

        coordinator.didSelectNetwork(blockchain: blockchain)
    }
}
