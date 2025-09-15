//
//  VisaReceiveAssetInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

class VisaReceiveAssetInfoProvider: ReceiveAddressTypesProvider {
    var receiveAddressTypes: [ReceiveAddressType] {
        addressInfos.map { .address($0) }
    }

    var receiveAddressInfos: [ReceiveAddressInfo] {
        addressInfos
    }

    // MARK: - Private Properties

    private let addressInfos: [ReceiveAddressInfo]

    // MARK: - Init

    init(_ addressInfos: [ReceiveAddressInfo]) {
        self.addressInfos = addressInfos
    }
}
