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
        let fallbackMemo = data.extraDestinationId?.nilIfEmpty

        switch parsed {
        case .contractCall(let call):
            try validate(
                destination: call.contractAddress,
                valueSun: call.callValue,
                owner: call.ownerAddress,
                against: data,
                expectedOwner: expectedOwner
            )

            return .contractCall(TronDEXContractCall(
                contractAddress: call.contractAddress,
                callData: call.callData,
                callValue: Decimal(call.callValue) / blockchain.decimalValue,
                feeLimit: call.feeLimit,
                memo: call.memo ?? fallbackMemo
            ))

        case .transfer(let transfer):
            try validate(
                destination: transfer.destinationAddress,
                valueSun: transfer.amount,
                owner: transfer.ownerAddress,
                against: data,
                expectedOwner: expectedOwner
            )

            return .transfer(TronDEXTransfer(
                destinationAddress: transfer.destinationAddress,
                amount: Decimal(transfer.amount) / blockchain.decimalValue,
                memo: transfer.memo ?? fallbackMemo
            ))
        }
    }

    private func validate(
        destination: String,
        valueSun: Int64,
        owner: String,
        against data: ExpressTransactionData,
        expectedOwner: String?
    ) throws {
        guard destination == data.destinationAddress else {
            throw TronDEXTransactionMapperError.destinationAddressMismatch
        }

        guard Decimal(valueSun) / blockchain.decimalValue == data.txValue else {
            throw TronDEXTransactionMapperError.valueMismatch
        }

        if let expectedOwner, owner != expectedOwner {
            throw TronDEXTransactionMapperError.ownerAddressMismatch
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
    /// A cap below the quoted fee reverts with `OUT_OF_ENERGY` and the energy already burnt,
    /// while raising the cap costs nothing — it isn't itself charged.
    func adjustedFeeLimit(covering fee: BSDKFee, blockchain: Blockchain) -> Int64 {
        let estimatedSun = (fee.amount.value * blockchain.decimalValue).rounded(roundingMode: .up)

        return max(
            feeLimit ?? TronTransactionParams.defaultSmartContractFeeLimit,
            (estimatedSun as NSDecimalNumber).int64Value
        )
    }
}

struct TronDEXTransfer {
    let destinationAddress: String
    /// In coin units.
    let amount: Decimal
    let memo: String?
}

enum TronDEXTransactionMapperError: String, Hashable, LocalizedError {
    case destinationAddressMismatch
    case valueMismatch
    case ownerAddressMismatch

    var errorDescription: String? {
        switch self {
        case .destinationAddressMismatch: "The provider transaction targets a different destination than the swap declares."
        case .valueMismatch: "The provider transaction moves a different value than the swap declares."
        case .ownerAddressMismatch: "The provider transaction was built for a different owner address."
        }
    }
}
