//
//  AddCustomTokenNetworksListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BlockchainSdkLocal

final class AddCustomTokenNetworksListViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var itemViewModels: [AddCustomTokenNetworksListItemViewModel] = []

    // MARK: - Dependencies

    weak var delegate: AddCustomTokenNetworkSelectorDelegate?

    init(selectedBlockchainNetworkId: String?, blockchains: [Blockchain]) {
        itemViewModels = blockchains.map { blockchain in
            AddCustomTokenNetworksListItemViewModel(
                networkId: blockchain.networkId,
                iconName: blockchain.iconNameFilled,
                networkName: blockchain.displayName,
                currencySymbol: blockchain.currencySymbol,
                isSelected: blockchain.networkId == selectedBlockchainNetworkId
            ) { [weak self] in
                self?.didTapNetwork(blockchain)
            }
        }
    }

    func didTapNetwork(_ blockchain: Blockchain) {
        for itemViewModel in itemViewModels {
            itemViewModel.isSelected = (blockchain.networkId == itemViewModel.networkId)
        }

        delegate?.didSelectNetwork(networkId: blockchain.networkId)
    }
}
