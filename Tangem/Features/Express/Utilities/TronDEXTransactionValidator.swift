//
//  TronDEXTransactionValidator.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress

/// Cross-checks a provider-built Tron transaction against the Express DTO the user agreed to
/// and the wallet's own address, so a transaction targeting another destination, moving another
/// value or built for another owner is rejected before it's priced or signed.
enum TronDEXTransactionValidator {
    static func validate(
        _ parsed: TronRawTransactionParser.ParsedTransaction,
        against data: ExpressTransactionData,
        expectedOwner: String?,
        blockchain: Blockchain
    ) throws {
        switch parsed {
        case .contractCall(let call):
            try validate(
                destination: call.contractAddress,
                valueSun: call.callValue,
                owner: call.ownerAddress,
                against: data,
                expectedOwner: expectedOwner,
                blockchain: blockchain
            )

        case .transfer(let transfer):
            try validate(
                destination: transfer.destinationAddress,
                valueSun: transfer.amount,
                owner: transfer.ownerAddress,
                against: data,
                expectedOwner: expectedOwner,
                blockchain: blockchain
            )
        }
    }
}

private extension TronDEXTransactionValidator {
    static func validate(
        destination: String,
        valueSun: Int64,
        owner: String,
        against data: ExpressTransactionData,
        expectedOwner: String?,
        blockchain: Blockchain
    ) throws {
        guard destination == data.destinationAddress else {
            throw TronDEXTransactionValidationError.destinationAddressMismatch
        }

        guard Decimal(valueSun) / blockchain.decimalValue == data.txValue else {
            throw TronDEXTransactionValidationError.valueMismatch
        }

        if let expectedOwner, owner != expectedOwner {
            throw TronDEXTransactionValidationError.ownerAddressMismatch
        }
    }
}

enum TronDEXTransactionValidationError: String, Hashable, LocalizedError {
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
