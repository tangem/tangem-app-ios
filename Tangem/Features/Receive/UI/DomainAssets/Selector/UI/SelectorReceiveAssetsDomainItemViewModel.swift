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

    // MARK: - Private Properties

    private let domainName: String
    private let addressInfo: ReceiveAddressInfo
    private weak var coordinator: SelectorReceiveAssetItemRoutable?

    // MARK: - Init

    init(domainName: String, addressInfo: ReceiveAddressInfo, coordinator: SelectorReceiveAssetItemRoutable?) {
        self.domainName = domainName
        self.addressInfo = addressInfo
        self.coordinator = coordinator
    }

    // MARK: - Actions

    func itemButtonDidTap() {
        coordinator?.routeOnReceiveQR(with: addressInfo)
    }

    func copyAddressButtonDidTap() {
        coordinator?.copyToClipboard(with: addressInfo.address)
    }
}
