//
//  BlockchainAccountInitializationService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// currently implemented only by TONWalletManager
public protocol BlockchainAccountInitializationService {
    func isAccountInitialized() async throws -> Bool
    func estimateInitializationFee() async throws -> Fee
    func initializationTransaction(fee: Fee) -> Transaction
}
