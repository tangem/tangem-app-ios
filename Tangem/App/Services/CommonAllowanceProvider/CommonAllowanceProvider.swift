//
//  CommonAllowanceProvider.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping
import BlockchainSdk

class CommonAllowanceProvider {
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let ethereumTransactionProcessor: EthereumTransactionProcessor

    init(
        ethereumNetworkProvider: EthereumNetworkProvider,
        ethereumTransactionProcessor: EthereumTransactionProcessor
    ) {
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.ethereumTransactionProcessor = ethereumTransactionProcessor
    }
}

// MARK: - AllowanceProvider

extension CommonAllowanceProvider: AllowanceProvider {
    func getAllowance(owner: String, to spender: String, contract: String) async throws -> Decimal {
        let allowance = try await ethereumNetworkProvider.getAllowance(
            owner: owner,
            spender: spender,
            contractAddress: contract
        ).async()

        return allowance
    }

    func makeApproveData(spender: String, amount: Decimal) -> Data {
        ethereumTransactionProcessor.buildForApprove(spender: spender, amount: amount)
    }
}
