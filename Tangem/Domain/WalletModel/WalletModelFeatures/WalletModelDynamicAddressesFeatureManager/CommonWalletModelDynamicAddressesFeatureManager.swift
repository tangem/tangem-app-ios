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

    // MARK: - Feature

    var dynamicAddressesManagerPublisher: AnyPublisher<DynamicAddressesManager?, Never> {
        .just(output: dynamicAddressesManager)
    }
}
