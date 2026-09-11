//
//  PolymarketDepositTransactionValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct PolymarketDepositTransactionValidator: SendTransactionValidator {
    func validate(amount: Amount) throws {
        throw PolymarketDepositSendingUnsupportedError.sendingUnsupported
    }

    func validate(amount: Amount, fee: Fee) throws {
        throw PolymarketDepositSendingUnsupportedError.sendingUnsupported
    }

    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        throw PolymarketDepositSendingUnsupportedError.sendingUnsupported
    }
}
