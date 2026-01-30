//
//  EarnNetworkFilterBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import BlockchainSdk
import TangemAssets
import TangemLocalization

extension AddCustomTokenNetworksListItemViewModel: Identifiable {
    var id: String { networkId }
}

final class EarnNetworkFilterBottomSheetViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var currentSelection: EarnNetworkFilterType
    @Published var presetRowViewModels: [DefaultSelectableRowViewModel<EarnNetworkFilterType>]
    @Published var networkItemViewModels: [AddCustomTokenNetworksListItemViewModel] = []

    var title: String {
        Localization.earnFilterAllNetworks
    }

    var selectionBinding: Binding<EarnNetworkFilterType> {
        Binding(
            get: { [weak self] in self?.currentSelection ?? .all },
            set: { [weak self] newValue in
                self?.selectAndDismiss(network: newValue)
            }
        )
    }

    // MARK: - Identifiable

    let id = UUID()

    // MARK: - Private Properties

    private let provider: EarnFilterProvider
    private let dismiss: (() -> Void)?

    // MARK: - Init

    init(
        provider: EarnFilterProvider,
        blockchainIconProvider: NetworkImageProvider = NetworkImageProvider(),
        onDismiss: (() -> Void)? = nil
    ) {
        self.provider = provider
        dismiss = onDismiss
        currentSelection = provider.currentFilterValue.network

        presetRowViewModels = EarnNetworkFilterType.presetCases.map {
            DefaultSelectableRowViewModel(
                id: $0,
                title: $0.description,
                subtitle: nil
            )
        }

        networkItemViewModels = SupportedBlockchains.all
            .map { blockchain in
                let isSelected: Bool
                if case .network(let networkId) = currentSelection {
                    isSelected = blockchain.networkId == networkId
                } else {
                    isSelected = false
                }
                return AddCustomTokenNetworksListItemViewModel(
                    networkId: blockchain.networkId,
                    iconAsset: blockchainIconProvider.provide(by: blockchain, filled: true),
                    networkName: blockchain.displayName,
                    currencySymbol: blockchain.currencySymbol,
                    isSelected: isSelected
                ) { [weak self] in
                    self?.selectAndDismiss(network: .network(networkId: blockchain.networkId))
                }
            }
    }

    // MARK: - Private Methods

    private func selectAndDismiss(network: EarnNetworkFilterType) {
        currentSelection = network
        provider.didSelectNetwork(network)
        dismiss?()
    }
}
