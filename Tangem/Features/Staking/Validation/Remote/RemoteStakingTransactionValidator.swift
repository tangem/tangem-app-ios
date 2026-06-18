//
//  RemoteStakingTransactionValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Validates staking transactions via BlockAid API (Polygon, BNB, Solana).
struct RemoteStakingTransactionValidator: StakingTransactionValidator {
    private let network: BlockAidSupportedNetwork
    private let accountAddress: String
    private let verifier: BlockAidStakingVerifier

    init(
        network: BlockAidSupportedNetwork,
        accountAddress: String,
        verifier: BlockAidStakingVerifier
    ) {
        self.network = network
        self.accountAddress = accountAddress
        self.verifier = verifier
    }

    func validate(_ unsignedTransactions: [String]) async throws {
        for unsignedData in unsignedTransactions {
            try await verifier.verify(
                network: network,
                accountAddress: accountAddress,
                unsignedTransaction: unsignedData
            )
        }
    }
}
