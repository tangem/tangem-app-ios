//
//  NFTNetworkSelectionListViewModel.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization
import struct TangemUIUtils.AlertBinder

public final class NFTNetworkSelectionListViewModel: ObservableObject {
    @Published var alert: AlertBinder?

    private(set) var allItems: [NFTNetworkSelectionListItemViewData] = []
    private var _allItems: [NFTNetworkSelectionListItemViewData] = []

    private(set) var availableItems: [NFTNetworkSelectionListItemViewData] = []
    private var _availableItems: [NFTNetworkSelectionListItemViewData] = []

    private(set) var unavailableItems: [NFTNetworkSelectionListItemViewData] = []
    private var _unavailableItems: [NFTNetworkSelectionListItemViewData] = []

    var title: String { Localization.nftReceiveTitle }

    var subtitle: String { Localization.hotCryptoAddTokenSubtitle(userWalletName) }

    var searchText: String {
        get { searchTextSubject.value }
        set { searchTextSubject.value = newValue }
    }

    // Using subject instead of a `Published` property to prevent too frequent UI redraws
    private let searchTextSubject = CurrentValueSubject<String, Never>("")
    private var searchTextSubscription: AnyCancellable?
    private var didBind = false

    private let userWalletName: String
    private let dataSource: NFTNetworkSelectionListDataSource
    private let tokenIconInfoProvider: NFTTokenIconInfoProvider
    private let nftChainNameProviding: NFTChainNameProviding
    private let analytics: NFTAnalytics.BlockchainSelection
    private weak var coordinator: NFTNetworkSelectionListRoutable?

    /// - Note: Retains data source.
    public init(
        userWalletName: String,
        dataSource: NFTNetworkSelectionListDataSource,
        tokenIconInfoProvider: NFTTokenIconInfoProvider,
        nftChainNameProviding: NFTChainNameProviding,
        analytics: NFTAnalytics.BlockchainSelection,
        coordinator: NFTNetworkSelectionListRoutable?
    ) {
        self.userWalletName = userWalletName
        self.dataSource = dataSource
        self.tokenIconInfoProvider = tokenIconInfoProvider
        self.nftChainNameProviding = nftChainNameProviding
        self.coordinator = coordinator
        self.analytics = analytics

        buildItems()
        filterItemViewModels()
    }

    func onViewAppear() {
        bind()
    }

    func onCloseButtonTap() {
        coordinator?.dismiss()
    }

    private func bind() {
        if didBind { return }

        searchTextSubscription = searchTextSubject
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, searchText in
                viewModel.filterItemViewModels(by: searchText)
            }

        didBind = true
    }

    private func buildItems() {
        let allSupportedChains = dataSource.allSupportedChains()
        var availableChains: [NFTChainItem] = []
        var unavailableChains: [NFTChainItem] = []

        for chain in allSupportedChains {
            if dataSource.isSupportedChainAvailable(chain) {
                availableChains.append(chain)
            } else {
                unavailableChains.append(chain)
            }
        }

        if unavailableChains.isEmpty {
            // If there are no unavailable items - we put all available items into the `allItems` section
            _allItems = allSupportedChains.map { chain in
                return NFTNetworkSelectionListItemViewData(
                    title: nftChainNameProviding.provide(for: chain.nftChain),
                    tokenIconInfo: tokenIconInfoProvider.tokenIconInfo(for: chain.nftChain, isCustom: chain.isCustom),
                    isAvailable: true,
                    tapAction: { [weak self] in
                        self?.onAvailableItemTap(chain)
                    }
                )
            }
        } else {
            // Otherwise all items are divided into `available` and `unavailable` sections
            _availableItems = availableChains.map { chain in
                return NFTNetworkSelectionListItemViewData(
                    title: nftChainNameProviding.provide(for: chain.nftChain),
                    tokenIconInfo: tokenIconInfoProvider.tokenIconInfo(for: chain.nftChain, isCustom: chain.isCustom),
                    isAvailable: true,
                    tapAction: { [weak self] in
                        self?.onAvailableItemTap(chain)
                    }
                )
            }
            _unavailableItems = unavailableChains.map { chain in
                return NFTNetworkSelectionListItemViewData(
                    title: nftChainNameProviding.provide(for: chain.nftChain),
                    tokenIconInfo: tokenIconInfoProvider.tokenIconInfo(for: chain.nftChain, isCustom: chain.isCustom),
                    isAvailable: false,
                    tapAction: { [weak self] in
                        self?.onUnavailableItemTap(chain)
                    }
                )
            }
        }
    }

    private func filterItemViewModels(
        by searchText: String? = nil
    ) {
        filterItemViewModels(source: \._allItems, destination: \.allItems, by: searchText)
        filterItemViewModels(source: \._availableItems, destination: \.availableItems, by: searchText)
        filterItemViewModels(source: \._unavailableItems, destination: \.unavailableItems, by: searchText)
        // Emit `objectWillChange` manually to prevent too frequent VM updates
        objectWillChange.send()
    }

    private func filterItemViewModels(
        source sourceKeyPath: KeyPath<NFTNetworkSelectionListViewModel, [NFTNetworkSelectionListItemViewData]>,
        destination destinationKeyPath: ReferenceWritableKeyPath<NFTNetworkSelectionListViewModel, [NFTNetworkSelectionListItemViewData]>,
        by searchText: String?
    ) {
        guard let searchText = searchText?.nilIfEmpty else {
            self[keyPath: destinationKeyPath] = self[keyPath: sourceKeyPath]
            return
        }

        self[keyPath: destinationKeyPath] = self[keyPath: sourceKeyPath].filter { item in
            item.title.localizedStandardContains(searchText) || item.tokenIconInfo.name.localizedStandardContains(searchText)
        }
    }

    private func onAvailableItemTap(_ nftChainItem: NFTChainItem) {
        coordinator?.openReceive(for: nftChainItem)
        analytics.logBlockchainChosen(nftChainNameProviding.provide(for: nftChainItem.nftChain))
    }

    private func onUnavailableItemTap(_ nftChainItem: NFTChainItem) {
        alert = AlertBinder(
            title: Localization.nftReceiveUnavailableAssetWarningTitle,
            message: Localization.nftReceiveUnavailableAssetWarningMessage
        )
    }
}
