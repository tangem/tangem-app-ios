//
//  TransactionFeeProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol TransactionFeeProvider {
    /// Use this method only for get a estimation fee
    /// Better use `getFee(amount:destination:)` for calculate the right fee for transaction
    func estimatedFee(amount: Amount) -> AnyPublisher<[Fee], Error>
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error>
}

public extension TransactionFeeProvider where Self: WalletProvider {
    func estimatedFee(amount: Amount) -> AnyPublisher<[Fee], Error> {
        do {
            let estimationFeeAddress = try EstimationFeeAddressFactory().makeAddress(for: wallet.blockchain)
            return getFee(amount: amount, destination: estimationFeeAddress)
        } catch {
            return .anyFail(error: error)
        }
    }
}

public protocol CompiledTransactionFeeProvider {
    func getFee(compiledTransaction data: Data) async throws -> [Fee]
}

public protocol GaslessTransactionFeeProvider {
    typealias YieldFeeOptions = GaslessYieldFeeOptions

    /// Estimates the gasless fee for a token transfer.
    func getGaslessFee(
        feeToken: Token,
        amount: Amount,
        destination: String,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal
    ) async throws -> Fee

    func getEstimatedGaslessFee(
        feeToken: Token,
        amount: Amount,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal
    ) async throws -> Fee

    func getEstimatedGaslessYieldFee(
        feeToken: Token,
        amount: Amount,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal,
        yieldFeeOptions: YieldFeeOptions
    ) async throws -> Fee

    /// Estimates the gasless fee for a transaction with pre-built calldata (approve, DEX swap, etc.).
    func getGaslessTransactionFee(
        feeToken: Token,
        destination: String,
        value: String?,
        data: Data?,
        stateOverride: EthereumStateOverride?,
        otherNativeFee: Decimal?,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal
    ) async throws -> Fee

    /// Estimates the gasless fee for a transaction using a pre-estimated gas limit.
    func getEstimatedGaslessTransactionFee(
        feeToken: Token,
        estimatedGasLimit: Int,
        otherNativeFee: Decimal?,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal
    ) async throws -> Fee

    /// Estimates the gasless fee when the fee token should be withdrawn from Yield Mode in the gasless batch.
    func getGaslessYieldFee(
        feeToken: Token,
        amount: Amount,
        destination: String,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal,
        yieldFeeOptions: YieldFeeOptions
    ) async throws -> Fee

    /// Estimates the gasless fee for a pre-built transaction and an extra Yield Mode withdraw call.
    func getGaslessYieldTransactionFee(
        feeToken: Token,
        destination: String,
        value: String?,
        data: Data?,
        otherNativeFee: Decimal?,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal,
        yieldFeeOptions: YieldFeeOptions
    ) async throws -> Fee

    /// Estimates the gasless fee from a pre-estimated transaction gas limit and an extra Yield Mode withdraw call.
    func getEstimatedGaslessYieldTransactionFee(
        feeToken: Token,
        estimatedGasLimit: Int,
        otherNativeFee: Decimal?,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal,
        yieldFeeOptions: YieldFeeOptions
    ) async throws -> Fee
}

public enum GaslessYieldUpgrade: Hashable {
    case none
    case required(implementation: String)

    public var isRequired: Bool {
        switch self {
        case .none:
            return false
        case .required:
            return true
        }
    }
}

public struct GaslessYieldFeeOptions {
    public let yieldContractAddress: String
    public let upgrade: GaslessYieldUpgrade

    public init(
        yieldContractAddress: String,
        upgrade: GaslessYieldUpgrade
    ) {
        self.yieldContractAddress = yieldContractAddress
        self.upgrade = upgrade
    }
}

public extension GaslessTransactionFeeProvider where Self: WalletProvider {
    func getEstimatedGaslessFee(feeToken: Token, amount: Amount, feeRecipientAddress: String, nativeToFeeTokenRate: Decimal) async throws -> Fee {
        let estimationFeeAddress = try EstimationFeeAddressFactory().makeAddress(for: wallet.blockchain)
        let fee = try await getGaslessFee(
            feeToken: feeToken,
            amount: amount,
            destination: estimationFeeAddress,
            feeRecipientAddress: feeRecipientAddress,
            nativeToFeeTokenRate: nativeToFeeTokenRate
        )
        return fee
    }

    func getEstimatedGaslessYieldFee(
        feeToken: Token,
        amount: Amount,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal,
        yieldFeeOptions: YieldFeeOptions
    ) async throws -> Fee {
        let estimationFeeAddress = try EstimationFeeAddressFactory().makeAddress(for: wallet.blockchain)
        return try await getGaslessYieldFee(
            feeToken: feeToken,
            amount: amount,
            destination: estimationFeeAddress,
            feeRecipientAddress: feeRecipientAddress,
            nativeToFeeTokenRate: nativeToFeeTokenRate,
            yieldFeeOptions: yieldFeeOptions
        )
    }
}
