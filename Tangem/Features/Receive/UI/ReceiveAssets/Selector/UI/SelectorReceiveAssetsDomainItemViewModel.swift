//
//  SelectorReceiveAssetsDomainItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAssets

final class SelectorReceiveAssetsDomainItemViewModel: Identifiable, ObservableObject {
    let domainName: String
    let addressIconViewModel: AddressIconViewModel

    // MARK: - Private Properties

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
        addressIconViewModel = AddressIconViewModel(address: domainName)
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
