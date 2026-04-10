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
    let dynamicAddressesManager: DynamicAddressesManager?

    init(dynamicAddressesManager: DynamicAddressesManager?) {
        self.dynamicAddressesManager = dynamicAddressesManager
    }
}

// MARK: - WalletModelDynamicAddressesFeatureManager protocol conformance

extension CommonWalletModelDynamicAddressesFeatureManager: WalletModelDynamicAddressesFeatureManager {
    var dynamicAddressesFeature: WalletModelFeature? {
        dynamicAddressesManager.map { .dynamicAddresses(manager: $0) }
    }

    var dynamicAddressesFeaturePublisher: AnyPublisher<WalletModelFeature?, Never> {
        .just(output: dynamicAddressesFeature)
    }
}
