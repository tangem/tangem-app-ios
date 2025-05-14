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

    private(set) var allItems: [NFTNetworkSelectionListItemViewData]
    private(set) var availableItems: [NFTNetworkSelectionListItemViewData]
    private(set) var unavailableItems: [NFTNetworkSelectionListItemViewData]

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
    private weak var coordinator: NFTNetworkSelectionListRoutable?

    /// - Note: Retains data source.
    public init(
        userWalletName: String,
        dataSource: NFTNetworkSelectionListDataSource,
        tokenIconInfoProvider: NFTTokenIconInfoProvider,
        nftChainNameProviding: NFTChainNameProviding,
        coordinator: NFTNetworkSelectionListRoutable?
    ) {
        self.userWalletName = userWalletName
        self.dataSource = dataSource
        self.tokenIconInfoProvider = tokenIconInfoProvider
        self.nftChainNameProviding = nftChainNameProviding
        self.coordinator = coordinator
        allItems = []
        availableItems = []
        unavailableItems = []
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
            allItems = allSupportedChains.map { chain in
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
            availableItems = availableChains.map { chain in
                return NFTNetworkSelectionListItemViewData(
                    title: nftChainNameProviding.provide(for: chain.nftChain),
                    tokenIconInfo: tokenIconInfoProvider.tokenIconInfo(for: chain.nftChain, isCustom: chain.isCustom),
                    isAvailable: true,
                    tapAction: { [weak self] in
                        self?.onAvailableItemTap(chain)
                    }
                )
            }
            unavailableItems = unavailableChains.map { chain in
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
        filterItemViewModels(at: \.allItems, by: searchText)
        filterItemViewModels(at: \.availableItems, by: searchText)
        filterItemViewModels(at: \.unavailableItems, by: searchText)
        // Emit `objectWillChange` manually to prevent too frequent VM updates
        objectWillChange.send()
    }

    private func filterItemViewModels(
        at keyPath: ReferenceWritableKeyPath<NFTNetworkSelectionListViewModel, [NFTNetworkSelectionListItemViewData]>,
        by searchText: String?
    ) {
        guard let searchText = searchText?.nilIfEmpty else {
            return
        }

        self[keyPath: keyPath] = self[keyPath: keyPath].filter { item in
            item.title.localizedStandardContains(searchText) || item.tokenIconInfo.name.localizedStandardContains(searchText)
        }
    }

    private func onAvailableItemTap(_ nftChainItem: NFTChainItem) {
        coordinator?.openReceive(for: nftChainItem)
    }

    private func onUnavailableItemTap(_ nftChainItem: NFTChainItem) {
        alert = AlertBinder(
            title: Localization.nftReceiveUnavailableAssetWarningTitle,
            message: Localization.nftReceiveUnavailableAssetWarningMessage
        )
    }
}
