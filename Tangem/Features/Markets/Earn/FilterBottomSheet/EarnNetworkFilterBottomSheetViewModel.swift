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
import protocol TangemUI.FloatingSheetContentViewModel
import protocol TangemUI.TabNavigationItem

@MainActor
final class EarnNetworkFilterBottomSheetViewModel: ObservableObject, Identifiable, FloatingSheetContentViewModel {
    // MARK: - ViewState

    @Published private(set) var networkRowInputs: [EarnNetworkFilterNetworkRowInput] = []
    @Published private(set) var isAllOptionSelected = true
    @Published private(set) var isFooterVisible = false

    let scopes = EarnNetworkFilterScope.allCases

    var title: String {
        Localization.earnFilterNetworks
    }

    var scopeBinding: Binding<EarnNetworkFilterScope> {
        Binding(
            get: { [weak self] in self?.draft.scope ?? .allNetworks },
            set: { [weak self] newValue in self?.select(scope: newValue) }
        )
    }

    // MARK: - Identifiable

    let id = UUID()

    // MARK: - Private Properties

    private let filterProvider: EarnDataFilterProvider
    private let analyticsProvider: EarnAnalyticsProvider
    private let blockchainIconProvider: NetworkImageProvider
    private let dismissAction: (() -> Void)?

    private let availableNetworks: [EarnNetworkInfo]
    private let myNetworks: [EarnNetworkInfo]
    private let appliedFilter: EarnNetworkFilterType
    private var draft: Selection

    // MARK: - Init

    init(
        filterProvider: EarnDataFilterProvider,
        analyticsProvider: EarnAnalyticsProvider,
        blockchainIconProvider: NetworkImageProvider = NetworkImageProvider(),
        onDismiss: (() -> Void)? = nil
    ) {
        self.filterProvider = filterProvider
        self.analyticsProvider = analyticsProvider
        self.blockchainIconProvider = blockchainIconProvider
        dismissAction = onDismiss

        availableNetworks = filterProvider.availableNetworks
        myNetworks = filterProvider.myNetworks

        appliedFilter = filterProvider.selectedNetworkFilter
        draft = Selection(filter: appliedFilter, availableNetworks: availableNetworks, myNetworks: myNetworks)

        updateState()
    }

    // MARK: - Internal Methods

    func onCloseTap() {
        dismiss()
    }

    func onAllOptionTap() {
        draft.networkId = nil
        updateState()
    }

    func onResetTap() {
        draft = Selection(scope: .allNetworks, networkId: nil)
        updateState()
    }

    func onApplyTap() {
        let filter = draft.filter(availableNetworks: availableNetworks, myNetworks: myNetworks)
        let (networkFilterType, networkId) = analyticsNetworkFilterParams(for: filter)
        analyticsProvider.logBestOpportunitiesFilterNetworkApplied(
            networkFilterType: networkFilterType,
            networkId: networkId
        )
        filterProvider.didSelectNetworkFilter(filter)
        dismiss()
    }

    // MARK: - Private Methods

    private func select(scope: EarnNetworkFilterScope) {
        let networkId = draft.networkId.flatMap { id in
            networks(of: scope).contains { $0.networkId == id } ? id : nil
        }
        draft = Selection(scope: scope, networkId: networkId)
        updateState()
    }

    private func select(networkId: String) {
        draft.networkId = networkId
        updateState()
    }

    private func networks(of scope: EarnNetworkFilterScope) -> [EarnNetworkInfo] {
        switch scope {
        case .allNetworks:
            availableNetworks
        case .myNetworks:
            myNetworks
        }
    }

    private func updateState() {
        let blockchainsByNetworkId = filterProvider.supportedBlockchainsByNetworkId

        networkRowInputs = networks(of: draft.scope).compactMap { networkInfo in
            guard let blockchain = blockchainsByNetworkId[networkInfo.networkId] else {
                return nil
            }

            return EarnNetworkFilterNetworkRowInput(
                id: blockchain.networkId,
                iconAsset: blockchainIconProvider.provide(by: blockchain, filled: true),
                networkName: blockchain.displayName,
                currencySymbol: blockchain.currencySymbol,
                isSelected: draft.networkId == networkInfo.networkId,
                onTap: { [weak self] in
                    self?.select(networkId: networkInfo.networkId)
                }
            )
        }

        isAllOptionSelected = draft.networkId == nil
        isFooterVisible = draft.filter(availableNetworks: availableNetworks, myNetworks: myNetworks) != appliedFilter
    }

    private func analyticsNetworkFilterParams(for network: EarnNetworkFilterType) -> (String, String) {
        switch network {
        case .all:
            return ("All Networks", "")
        case .userNetworks:
            return ("My Networks", "")
        case .specific(let networkInfo):
            return ("Specific", networkInfo.networkId)
        }
    }

    private func dismiss() {
        dismissAction?()
    }
}

// MARK: - Selection

private extension EarnNetworkFilterBottomSheetViewModel {
    /// `networkId == nil` means the scope's "All" option is selected.
    struct Selection {
        var scope: EarnNetworkFilterScope
        var networkId: String?

        init(scope: EarnNetworkFilterScope, networkId: String?) {
            self.scope = scope
            self.networkId = networkId
        }

        init(filter: EarnNetworkFilterType, availableNetworks: [EarnNetworkInfo], myNetworks: [EarnNetworkInfo]) {
            switch filter {
            case .all:
                self.init(scope: .allNetworks, networkId: nil)
            case .userNetworks:
                self.init(scope: .myNetworks, networkId: nil)
            case .specific(let networkInfo):
                let networkId = networkInfo.networkId
                // A specific network is scope-agnostic, so the sheet opens on the narrowest tab holding it.
                if myNetworks.contains(where: { $0.networkId == networkId }) {
                    self.init(scope: .myNetworks, networkId: networkId)
                } else if availableNetworks.contains(where: { $0.networkId == networkId }) {
                    self.init(scope: .allNetworks, networkId: networkId)
                } else {
                    self.init(scope: .allNetworks, networkId: nil)
                }
            }
        }

        func filter(availableNetworks: [EarnNetworkInfo], myNetworks: [EarnNetworkInfo]) -> EarnNetworkFilterType {
            if let networkId, let networkInfo = availableNetworks.first(where: { $0.networkId == networkId }) {
                return .specific(networkInfo: networkInfo)
            }

            switch scope {
            case .allNetworks:
                return .all
            case .myNetworks:
                return .userNetworks(networkInfos: myNetworks)
            }
        }
    }
}

// MARK: - EarnNetworkFilterScope

enum EarnNetworkFilterScope: CaseIterable, TabNavigationItem {
    case allNetworks
    case myNetworks

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .allNetworks:
            Localization.earnFilterAllNetworks
        case .myNetworks:
            Localization.earnFilterMyNetworks
        }
    }
}
