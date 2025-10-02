//
//  SelectorReceiveAssetsAddressPageItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAssets
import TangemUI
import TangemLocalization

class SelectorReceiveAssetsAddressPageItemViewModel: Identifiable, ObservableObject {
    var title: String {
        makeTitleItemStateView()
    }

    var tokenIconInfo: TokenIconInfo {
        TokenIconInfoBuilder().build(from: tokenItem, isCustom: false)
    }

    var address: String {
        addressInfo.address
    }

    // MARK: - Private Properties

    private let tokenItem: TokenItem
    private let addressInfo: ReceiveAddressInfo
    private let analyticsLogger: ItemSelectorReceiveAssetsAnalyticsLogger
    private weak var coordinator: SelectorReceiveAssetItemRoutable?

    // MARK: - Init

    init(
        tokenItem: TokenItem,
        addressInfo: ReceiveAddressInfo,
        analyticsLogger: ItemSelectorReceiveAssetsAnalyticsLogger,
        coordinator: SelectorReceiveAssetItemRoutable?
    ) {
        self.tokenItem = tokenItem
        self.addressInfo = addressInfo
        self.analyticsLogger = analyticsLogger
        self.coordinator = coordinator
    }

    // MARK: - Actions

    func itemButtonDidTap() {
        coordinator?.routeOnReceiveQR(with: addressInfo)
    }

    func qrCodeButtonDidTap() {
        coordinator?.routeOnReceiveQR(with: addressInfo)
    }

    func copyAddressButtonDidTap() {
        analyticsLogger.logCopyAddressButtonTapped()
        coordinator?.copyToClipboard(with: addressInfo.address)
    }

    // MARK: - Private Implementation

    private func makeTitleItemStateView() -> String {
        Localization.domainReceiveAssetsNetworkNameAddress(tokenItem.name.capitalizingFirstLetter())
    }
}
