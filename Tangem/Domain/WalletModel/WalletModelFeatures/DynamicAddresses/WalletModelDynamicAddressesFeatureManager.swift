//
//  WalletModelDynamicAddressesFeatureManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class WalletModelDynamicAddressesFeatureManager {
    let dynamicAddressesManager: DynamicAddressesManager?

    init(dynamicAddressesManager: DynamicAddressesManager?) {
        self.dynamicAddressesManager = dynamicAddressesManager
    }
}

// MARK: - WalletModelFeatureManager protocol conformance

extension WalletModelDynamicAddressesFeatureManager: WalletModelFeatureManager {
    var featurePayload: DynamicAddressesManager? { dynamicAddressesManager }

    var featurePayloadPublisher: AnyPublisher<DynamicAddressesManager?, Never> {
        .just(output: dynamicAddressesManager)
    }
}
