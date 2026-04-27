//
//  WalletModelFeaturesManagerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct WalletModelFeaturesManagerMock {}

// MARK: - WalletModelFeaturesManager protocol conformance

extension WalletModelFeaturesManagerMock: WalletModelFeaturesManager {
    var features: [WalletModelFeature] { [] }
    var featuresPublisher: AnyPublisher<[WalletModelFeature], Never> { .just(output: []) }
}
