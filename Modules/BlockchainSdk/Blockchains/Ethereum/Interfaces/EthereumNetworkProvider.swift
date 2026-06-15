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
        stateOverride: [String: EthereumAccountOverride]?
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
    /// Whether this error represents an EVM `execution reverted` response.
    var isEVMExecutionReverted: Bool {
        if let apiError = self as? JSONRPC.APIError {
            return apiError.isContractExecutionError
        }

        if let multiError = self as? MultiNetworkProviderError, let apiError = multiError.networkError as? JSONRPC.APIError {
            return apiError.isContractExecutionError
        }

        return false
    }
}

extension JSONRPC.APIError {
    /// EIP-1474 defines code 3 for failed contract execution; some nodes omit
    /// the code and report reverts with only the message filled in.
    var isContractExecutionError: Bool {
        if code == Self.executionRevertedCode {
            return true
        }

        return message?.range(of: Self.executionRevertedMessage, options: .caseInsensitive) != nil
    }

    private static let executionRevertedCode = 3
    private static let executionRevertedMessage = "execution reverted"
}
