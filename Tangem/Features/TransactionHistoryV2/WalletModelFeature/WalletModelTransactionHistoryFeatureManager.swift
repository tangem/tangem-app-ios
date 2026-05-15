//
//  WalletModelTransactionHistoryFeatureManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol WalletModelTransactionHistoryFeatureManager {
    var transactionHistoryFeature: WalletModelFeature? { get }
    var transactionHistoryFeaturePublisher: AnyPublisher<WalletModelFeature?, Never> { get }
}
