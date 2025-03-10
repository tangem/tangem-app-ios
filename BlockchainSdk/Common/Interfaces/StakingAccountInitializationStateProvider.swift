//
//  StakingAccountInitializationStateProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// Used to disable staking operations on non-initialized accounts
/// because it may lead to errors on StakeKit requests
/// currently implemented only by TONWalletManager
public protocol StakingAccountInitializationStateProvider {
    var isAccountInitialized: Bool { get }
}
