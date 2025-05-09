//
//  WalletModelFeaturesManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol WalletModelFeaturesManager {
    var featuresPublisher: AnyPublisher<[WalletModelFeature], Never> { get }
}
