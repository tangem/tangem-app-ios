//
//  TronGaslessFeeParameters.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk
import TangemFoundation

struct TronGaslessFeeParameters: FeeParameters {
    let quoteId: String
    let request: TronGaslessQuoteRequest
    let feeRecipient: String
    let compensationToken: String
    let compensationAmountRaw: String
    let expiresAt: Date
    let energy: Int
    let bandwidth: Int
    let trxCost: String
}

extension TronGaslessFeeParameters {
    static let expirationBuffer: TimeInterval = 60
}

struct TronFeeLimitCalculator {
    func calculate(
        providerFeeLimit: Int64?,
        covering fee: BSDKFee,
        blockchain: Blockchain
    ) throws -> Int64 {
        let estimatedFee: Decimal
        let effectiveProviderFeeLimit: Int64?
        if let parameters = fee.parameters as? TronGaslessFeeParameters {
            guard let trxCost = Decimal(stringValue: parameters.trxCost), trxCost > 0 else {
                throw TronFeeLimitError.invalidGaslessTrxCost(parameters.trxCost)
            }

            estimatedFee = trxCost
            effectiveProviderFeeLimit = nil
        } else {
            estimatedFee = fee.amount.value
            effectiveProviderFeeLimit = providerFeeLimit
        }

        let estimatedSunDecimal = (estimatedFee * blockchain.decimalValue).rounded(roundingMode: .up)
        guard estimatedSunDecimal <= Decimal(Int64.max) else {
            throw TronFeeLimitError.feeLimitOverflow
        }

        let estimatedSun = estimatedSunDecimal.int64Value
        let (multipliedEstimatedSun, overflow) = estimatedSun.multipliedReportingOverflow(by: feeLimitCeilingMultiplier)
        guard !overflow else {
            throw TronFeeLimitError.feeLimitOverflow
        }

        let ceiling = max(multipliedEstimatedSun, TronTransactionParams.defaultSmartContractFeeLimit)

        return clamp(
            effectiveProviderFeeLimit ?? TronTransactionParams.defaultSmartContractFeeLimit,
            min: estimatedSun,
            max: ceiling
        )
    }

    private let feeLimitCeilingMultiplier: Int64 = 3
}

enum TronFeeLimitError: LocalizedError {
    case invalidGaslessTrxCost(String)
    case feeLimitOverflow

    var errorDescription: String? {
        switch self {
        case .invalidGaslessTrxCost(let value): "Invalid Tron gasless TRX cost: \(value)"
        case .feeLimitOverflow: "Tron fee limit exceeds the supported range"
        }
    }
}

struct TronGaslessQuoteRequest: Equatable {
    let sourceAddress: String
    let tokenContractAddress: String
    let amountRaw: BigUInt
    let feeTokenContractAddress: String
    let operation: Operation

    func matches(transaction: BSDKTransaction, feeToken: BSDKToken) -> Bool {
        guard sourceAddress == transaction.sourceAddress,
              feeTokenContractAddress == feeToken.contractAddress else {
            return false
        }

        switch operation {
        case .transfer:
            return matches(
                amount: transaction.amount,
                destinationAddress: transaction.destinationAddress,
                feeToken: feeToken
            )
        case .approve(let contractAddress, _, let callData),
             .swap(let contractAddress, let callData, _):
            guard transaction.destinationAddress == contractAddress,
                  transaction.contractAddress == contractAddress,
                  let params = transaction.params as? TronTransactionParams,
                  case .contractCall(let transactionCallData, _) = params.transactionType else {
                return false
            }

            return transactionCallData == callData
        }
    }

    func matches(amount: BSDKAmount, destinationAddress: String, feeToken: BSDKToken) -> Bool {
        guard let tokenContractAddress = amount.type.token?.contractAddress,
              let amountRaw = amount.bigUIntValue else {
            return false
        }

        guard case .transfer(let expectedDestinationAddress) = operation else {
            return false
        }

        return expectedDestinationAddress == destinationAddress
            && self.tokenContractAddress == tokenContractAddress
            && self.amountRaw == amountRaw
            && feeTokenContractAddress == feeToken.contractAddress
    }

    enum Operation: Equatable {
        case transfer(destinationAddress: String)
        case approve(contractAddress: String, spender: String, callData: Data)
        case swap(contractAddress: String, callData: Data, spender: String?)
    }
}

extension TronGaslessQuoteRequest {
    init(
        sourceAddress: String,
        destinationAddress: String,
        tokenContractAddress: String,
        amountRaw: BigUInt,
        feeTokenContractAddress: String
    ) {
        self.sourceAddress = sourceAddress
        self.tokenContractAddress = tokenContractAddress
        self.amountRaw = amountRaw
        self.feeTokenContractAddress = feeTokenContractAddress
        operation = .transfer(destinationAddress: destinationAddress)
    }
}
