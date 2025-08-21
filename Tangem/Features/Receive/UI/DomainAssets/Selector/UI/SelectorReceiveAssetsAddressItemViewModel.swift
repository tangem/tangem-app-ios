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
    var header: String {
        if tokenItem.isToken {
            return "\(tokenItem.name.capitalizingFirstLetter()) • \(tokenItem.blockchain.tokenTypeName ?? "")"
        } else {
            return "\(tokenItem.name.capitalizingFirstLetter())"
        }
    }

    var address: String {
        addressInfo.address
    }

    // MARK: - Private Properties

    private let tokenItem: TokenItem
    private let addressInfo: ReceiveAddressInfo
    private weak var coordinator: SelectorReceiveAssetItemRoutable?

    // MARK: - Init

    init(tokenItem: TokenItem, addressInfo: ReceiveAddressInfo, coordinator: SelectorReceiveAssetItemRoutable?) {
        self.tokenItem = tokenItem
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
