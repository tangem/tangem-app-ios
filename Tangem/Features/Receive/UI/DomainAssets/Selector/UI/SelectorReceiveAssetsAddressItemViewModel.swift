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
    let header: String

    var address: String {
        addressInfo.address
    }

    // MARK: - Private Properties

    private let addressInfo: ReceiveAddressInfo
    private weak var coordinator: SelectorReceiveAssetItemRoutable?

    // MARK: - Init

    init(header: String, addressInfo: ReceiveAddressInfo, coordinator: SelectorReceiveAssetItemRoutable?) {
        self.header = header
        self.addressInfo = addressInfo
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
        coordinator?.copyToClipboard(with: addressInfo.address)
    }
}
