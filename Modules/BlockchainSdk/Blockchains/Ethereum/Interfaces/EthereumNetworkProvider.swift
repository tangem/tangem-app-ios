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
    func getFee(
        destination: String,
        value: String?,
        data: Data?,
        stateOverride: EthereumStateOverride?
    ) -> AnyPublisher<[Fee], Error>

    func getGasPrice() -> AnyPublisher<BigUInt, Error>
    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error>
    func getFeeHistory() -> AnyPublisher<EthereumFeeHistory, Error>

    func getAllowance(owner: String, spender: String, contractAddress: String) -> AnyPublisher<Decimal, Error>
    func getAllowanceRaw(owner: String, spender: String, contractAddress: String) -> AnyPublisher<String, Error>
    func getBalance(_ address: String) -> AnyPublisher<Decimal, Error>
    func getTxCount(_ address: String) -> AnyPublisher<Int, Error>
    func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error>
    func getSmartContractNonce(for address: String) -> AnyPublisher<Int, Error>
}

// MARK: - Default-arg call ergonomics

public extension EthereumNetworkProvider {
    /// Convenience overload — preserves existing call sites that don't care about state override.
    func getFee(destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        getFee(destination: destination, value: value, data: data, stateOverride: nil)
    }
}

// MARK: - Public helpers

public extension Error {
    /// Whether this error represents an EVM `execution reverted` response (JSON-RPC error code 3).
    var isEVMExecutionReverted: Bool {
        guard let multiError = self as? MultiNetworkProviderError,
              let apiError = multiError.networkError as? JSONRPC.APIError,
              apiError.code == 3
        else {
            return false
        }

        return true
    }
}
