//
//  EthereumGaslessDataProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol EthereumGaslessDataProvider {
    func prepareEIP7702AuthorizationData() async throws -> EIP7702AuthorizationData
    func getGaslessExecutorContractAddress() throws -> String
}
