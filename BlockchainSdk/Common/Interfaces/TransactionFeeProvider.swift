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
    var allowsFeeSelection: Bool { get }

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
    func getGaslessFee(feeToken: Token, amount: Amount, destination: String, feeRecipientAddress: String) async throws -> Fee
    func getEstimatedGaslessFee(feeToken: Token, amount: Amount, feeRecipientAddress: String) async throws -> Fee
}

public extension GaslessTransactionFeeProvider where Self: WalletProvider {
    func getEstimatedGaslessFee(feeToken: Token, amount: Amount, feeRecipientAddress: String) async throws -> Fee {
        let estimationFeeAddress = try EstimationFeeAddressFactory().makeAddress(for: wallet.blockchain)
        let fee = try await getGaslessFee(
            feeToken: feeToken,
            amount: amount,
            destination: estimationFeeAddress,
            feeRecipientAddress: feeRecipientAddress
        )
        return fee
    }
}
