//
//  SelectorReceiveAssetsAddressItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAssets

class SelectorReceiveAssetsAddressItemViewModel: Identifiable, ObservableObject {
    let title: String

    var address: String {
        addressInfo.address
    }

    // MARK: - Private Properties

    private let addressInfo: ReceiveAddressInfo
    private let analyticsLogger: ItemSelectorReceiveAssetsAnalyticsLogger
    private weak var coordinator: SelectorReceiveAssetItemRoutable?

    // MARK: - Init

    init(
        title: String,
        addressInfo: ReceiveAddressInfo,
        analyticsLogger: ItemSelectorReceiveAssetsAnalyticsLogger,
        coordinator: SelectorReceiveAssetItemRoutable?
    ) {
        self.title = title
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
}
