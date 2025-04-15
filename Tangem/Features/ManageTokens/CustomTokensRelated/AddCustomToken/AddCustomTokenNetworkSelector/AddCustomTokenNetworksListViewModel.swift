//
//  AddCustomTokenNetworksListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BlockchainSdk
import TangemAssets
import TangemFoundation

final class AddCustomTokenNetworksListViewModel: ObservableObject {
    // MARK: - ViewState

    @Published private(set) var itemViewModels: [AddCustomTokenNetworksListItemViewModel] = []

    var searchText: String {
        get { searchTextSubject.value }
        set { searchTextSubject.value = newValue }
    }

    // MARK: - Dependencies

    weak var delegate: AddCustomTokenNetworkSelectorDelegate?

    // MARK: - Internal

    private var allItemViewModels: [AddCustomTokenNetworksListItemViewModel] = []
    private let searchTextSubject = CurrentValueSubject<String, Never>("")
    private var searchTextSubscription: AnyCancellable?
    private var didBind = false

    init(
        selectedBlockchainNetworkId: String?,
        blockchains: [Blockchain],
        blockchainIconProvider: NetworkImageProvider = NetworkImageProvider()
    ) {
        allItemViewModels = blockchains.map { blockchain in
            AddCustomTokenNetworksListItemViewModel(
                networkId: blockchain.networkId,
                iconAsset: blockchainIconProvider.provide(by: blockchain, filled: true),
                networkName: blockchain.displayName,
                currencySymbol: blockchain.currencySymbol,
                isSelected: blockchain.networkId == selectedBlockchainNetworkId
            ) { [weak self] in
                self?.didTapNetwork(blockchain)
            }
        }

        filterItemViewModels()
    }

    func onViewAppear() {
        bind()
    }

    func didTapNetwork(_ blockchain: Blockchain) {
        for itemViewModel in itemViewModels {
            itemViewModel.isSelected = (blockchain.networkId == itemViewModel.networkId)
        }

        delegate?.didSelectNetwork(networkId: blockchain.networkId)
    }

    private func bind() {
        if didBind { return }

        searchTextSubscription = searchTextSubject
            .removeDuplicates()
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .sink(receiveValue: weakify(self, forFunction: AddCustomTokenNetworksListViewModel.filterItemViewModels))

        didBind = true
    }

    private func filterItemViewModels(searchText: String? = nil) {
        guard let searchText = searchText?.nilIfEmpty else {
            itemViewModels = allItemViewModels
            return
        }

        itemViewModels = allItemViewModels.filter { itemViewModel in
            return itemViewModel.searchTexts.contains { $0.localizedStandardContains(searchText) }
        }
    }
}
