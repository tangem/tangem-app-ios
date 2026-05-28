//
//  SendTransactionValidator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

protocol SendTransactionValidator {
    func validate(amount: Amount) throws
    func validate(amount: Amount, fee: Fee) throws
}
