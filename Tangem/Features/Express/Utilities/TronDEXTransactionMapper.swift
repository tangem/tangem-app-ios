//
//  TronDEXTransactionMapper.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress

/// Express delivers Tron DEX `txData` as the provider's full native transaction, whose embedded
/// block reference is short-lived (see `TronRawTransactionParser`) — so the wallet lifts out the
/// payload (a smart-contract call or a plain transfer), cross-checks it against the DTO the user
/// agreed to, and rebuilds against a fresh block.
struct TronDEXTransactionMapper {
    let blockchain: Blockchain

    func map(data: ExpressTransactionData, expectedOwner: String?) throws -> TronDEXTransaction {
        guard let txData = data.txData else {
            throw ExpressProviderError.transactionDataNotFound
        }

        let rawTransaction = Data(hexString: txData)
        guard !rawTransaction.isEmpty else {
            throw ExpressProviderError.transactionDataNotFound
        }

        let parsed = try TronRawTransactionParser().parse(rawTransaction: rawTransaction)
        try TronDEXTransactionValidator.validate(parsed, against: data, expectedOwner: expectedOwner, blockchain: blockchain)

        let fallbackMemo = data.extraDestinationId?.nilIfEmpty

        switch parsed {
        case .contractCall(let call):
            return .contractCall(TronDEXContractCall(
                contractAddress: call.contractAddress,
                callData: call.callData,
                callValue: Decimal(call.callValue) / blockchain.decimalValue,
                feeLimit: call.feeLimit,
                memo: call.memo ?? fallbackMemo
            ))

        case .transfer(let transfer):
            return .transfer(TronDEXTransfer(
                destinationAddress: transfer.destinationAddress,
                amount: Decimal(transfer.amount) / blockchain.decimalValue,
                memo: transfer.memo ?? fallbackMemo
            ))
        }
    }
}

enum TronDEXTransaction {
    case contractCall(TronDEXContractCall)
    case transfer(TronDEXTransfer)
}

struct TronDEXContractCall {
    let contractAddress: String
    let callData: Data
    /// In coin units.
    let callValue: Decimal
    /// In sun; `nil` when the provider's transaction doesn't set one.
    let feeLimit: Int64?
    let memo: String?
}

extension TronDEXContractCall {
    /// A cap below the quoted fee reverts with `OUT_OF_ENERGY` and the energy already burnt, while
    /// raising the cap costs nothing — it isn't itself charged. The provider's limit is in turn bounded
    /// by a multiple of our own estimate, so it can't set an arbitrarily high burn ceiling.
    func adjustedFeeLimit(covering fee: BSDKFee, blockchain: Blockchain) -> Int64 {
        let estimatedSun = ((fee.amount.value * blockchain.decimalValue).rounded(roundingMode: .up) as NSDecimalNumber).int64Value
        let ceiling = max(estimatedSun * Self.feeLimitCeilingMultiplier, TronTransactionParams.defaultSmartContractFeeLimit)

        return min(
            max(feeLimit ?? TronTransactionParams.defaultSmartContractFeeLimit, estimatedSun),
            ceiling
        )
    }

    private static let feeLimitCeilingMultiplier: Int64 = 3
}

struct TronDEXTransfer {
    let destinationAddress: String
    /// In coin units.
    let amount: Decimal
    let memo: String?
}
