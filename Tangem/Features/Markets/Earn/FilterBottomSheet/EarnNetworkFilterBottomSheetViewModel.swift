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

final class EarnNetworkFilterBottomSheetViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var currentSelection: EarnNetworkFilterType
    @Published var presetRowViewModels: [DefaultSelectableRowViewModel<EarnNetworkFilterType>]
    @Published var networkRowInputs: [EarnNetworkFilterNetworkRowInput] = []

    var title: String {
        Localization.earnFilterBy
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

    private let filterProvider: EarnDataFilterProvider
    private let dismissAction: (() -> Void)?

    // MARK: - Init

    init(
        filterProvider: EarnDataFilterProvider,
        blockchainIconProvider: NetworkImageProvider = NetworkImageProvider(),
        onDismiss: (() -> Void)? = nil
    ) {
        self.filterProvider = filterProvider
        dismissAction = onDismiss
        currentSelection = filterProvider.selectedNetworkFilter

        presetRowViewModels = [
            EarnNetworkFilterType.all,
            EarnNetworkFilterType.userNetworks(networkInfos: filterProvider.myNetworks),
        ].map {
            DefaultSelectableRowViewModel(
                id: $0,
                title: $0.displayTitle,
                subtitle: nil
            )
        }

        let blockchainsByNetworkId = Dictionary(
            uniqueKeysWithValues: SupportedBlockchains.all.map { ($0.networkId, $0) }
        )

        networkRowInputs = filterProvider.availableNetworks.compactMap { networkInfo in
            guard let blockchain = blockchainsByNetworkId[networkInfo.networkId] else {
                return nil
            }

            return EarnNetworkFilterNetworkRowInput(
                id: blockchain.networkId,
                iconAsset: blockchainIconProvider.provide(by: blockchain, filled: true),
                networkName: blockchain.displayName,
                currencySymbol: blockchain.currencySymbol,
                onTap: { [weak self] in
                    self?.selectAndDismiss(network: .specific(networkInfo: networkInfo))
                }
            )
        }
    }

    // MARK: - Private Methods

    private func selectAndDismiss(network: EarnNetworkFilterType) {
        currentSelection = network
        filterProvider.didSelectNetworkFilter(network)
        dismissAction?()
    }
}
