//
//  VisaReceiveAssetInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation

class VisaReceiveAssetInfoProvider: ReceiveAddressTypesProvider {
    var receiveAddressTypes: [ReceiveAddressType] {
        addressInfos.map { .address($0) }
    }

    var receiveAddressTypesPublisher: AnyPublisher<[ReceiveAddressType], Never> {
        .just(output: receiveAddressTypes)
    }

    // MARK: - Private Properties

    private let addressInfos: [ReceiveAddressInfo]

    // MARK: - Init

    init(_ addressInfos: [ReceiveAddressInfo]) {
        self.addressInfos = addressInfos
    }
}
