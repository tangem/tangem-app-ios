//
//  AccountsWalletModelsAggregator.swift
//  Tangem
//
//  Created on 13.10.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation

/// Provides flat list of all wallet models from all crypto accounts
protocol AccountsWalletModelsAggregating {
    var walletModelsPublisher: AnyPublisher<[any WalletModel], Never> { get }
}
