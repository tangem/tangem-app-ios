//
//  SelectorReceiveAssetsDomainItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAssets

class SelectorReceiveAssetsDomainItemViewModel: Identifiable, ObservableObject {
    var address: String {
        domainName
    }

    let addressIcon: AddressBlockiesIconViewData

    // MARK: - Private Properties

    private let domainName: String
    private let addressInfo: ReceiveAddressInfo
    private let analyticsLogger: ItemSelectorReceiveAssetsAnalyticsLogger
    private weak var coordinator: SelectorReceiveAssetItemRoutable?

    // MARK: - Init

    init(
        domainName: String,
        addressInfo: ReceiveAddressInfo,
        analyticsLogger: ItemSelectorReceiveAssetsAnalyticsLogger,
        coordinator: SelectorReceiveAssetItemRoutable?
    ) {
        self.domainName = domainName
        self.addressInfo = addressInfo
        self.analyticsLogger = analyticsLogger
        self.coordinator = coordinator

        addressIcon = AddressIconProvider.makeBlockiesIconViewData(address: domainName)
    }

    // MARK: - Actions

    func copyAddressButtonDidTap() {
        analyticsLogger.logCopyDomainNameAddressButtonTapped()
        coordinator?.copyToClipboard(with: domainName)
    }

    func shareAddressButtonDidTap() {
        analyticsLogger.logShareDomainNameAddressButtonTapped()
        coordinator?.share(with: domainName)
    }
}
