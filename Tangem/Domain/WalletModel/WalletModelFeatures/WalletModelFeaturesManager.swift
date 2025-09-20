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
    /// Synchronously returns the current list of features.
    ///
    /// - Note: Unlike `featuresPublisher`, this accessor provides a snapshot of the features at the moment of access.
    ///   It may not reflect the most up-to-date state if features are updated asynchronously.
    ///   Threading and freshness guarantees depend on the implementation; for real-time updates or to react to changes,
    ///   prefer subscribing to `featuresPublisher`.
    var features: [WalletModelFeature] { get }
