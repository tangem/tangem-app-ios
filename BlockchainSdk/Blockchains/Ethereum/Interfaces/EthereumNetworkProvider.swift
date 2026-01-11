//
//  EthereumNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt

public protocol EthereumNetworkProvider {
    func getFee(destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error>
    func getGasPrice() -> AnyPublisher<BigUInt, Error>
    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error>
    func getFeeHistory() -> AnyPublisher<EthereumFeeHistory, Error>

    func getAllowance(owner: String, spender: String, contractAddress: String) -> AnyPublisher<Decimal, Error>
    func getAllowanceRaw(owner: String, spender: String, contractAddress: String) -> AnyPublisher<String, Error>
    func getBalance(_ address: String) -> AnyPublisher<Decimal, Error>
    func getTxCount(_ address: String) -> AnyPublisher<Int, Error>
    func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error>
    func getSmartContractNonce() async throws -> BigUInt
}
