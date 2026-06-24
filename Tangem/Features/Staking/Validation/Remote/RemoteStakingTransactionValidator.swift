//
//  RemoteStakingTransactionValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Validates staking transactions via BlockAid API (Ethereum, BNB, Solana).
struct RemoteStakingTransactionValidator: StakingTransactionValidator {
    private let network: BlockaidSupportedNetwork
    private let accountAddress: String
    private let verifier: BlockaidStakingVerifier

    init(
        network: BlockaidSupportedNetwork,
        accountAddress: String,
        verifier: BlockaidStakingVerifier
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
