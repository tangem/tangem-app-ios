//
//  WalletModelDynamicAddressesFeatureManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol WalletModelDynamicAddressesFeatureManager {
    var dynamicAddressesFeature: WalletModelFeature? { get }
    var dynamicAddressesFeaturePublisher: AnyPublisher<WalletModelFeature?, Never> { get }
}
