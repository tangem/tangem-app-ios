//
//  CollectiblesDepositTransactionValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct CollectiblesDepositTransactionValidator: SendTransactionValidator {
    func validate(amount: Amount) throws {
        throw CollectiblesDepositSendingUnsupportedError.sendingUnsupported
    }

    func validate(amount: Amount, fee: Fee) throws {
        throw CollectiblesDepositSendingUnsupportedError.sendingUnsupported
    }

    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        throw CollectiblesDepositSendingUnsupportedError.sendingUnsupported
    }
}
