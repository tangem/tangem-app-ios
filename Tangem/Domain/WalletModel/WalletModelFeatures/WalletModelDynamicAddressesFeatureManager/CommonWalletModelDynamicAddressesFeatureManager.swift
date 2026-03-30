//
//  CommonWalletModelDynamicAddressesFeatureManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class CommonWalletModelDynamicAddressesFeatureManager {
    private let dynamicAddressesManager: DynamicAddressesManager

    init(dynamicAddressesManager: DynamicAddressesManager) {
        self.dynamicAddressesManager = dynamicAddressesManager
    }
}

// MARK: - WalletModelDynamicAddressesFeatureManager protocol conformance

extension CommonWalletModelDynamicAddressesFeatureManager: WalletModelDynamicAddressesFeatureManager {
    var dynamicAddressesFeaturePublisher: AnyPublisher<[WalletModelFeature], Never> {
        .just(output: [.dynamicAddresses(addressesManager: dynamicAddressesManager)])
    }
}
