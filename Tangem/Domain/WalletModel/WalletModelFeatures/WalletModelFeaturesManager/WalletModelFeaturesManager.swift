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
    var features: [WalletModelFeature] { get }
    var featuresPublisher: AnyPublisher<[WalletModelFeature], Never> { get }

    func configure(with walletModel: any WalletModel)
}
