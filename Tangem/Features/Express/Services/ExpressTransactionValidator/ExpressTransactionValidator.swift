//
//  ExpressTransactionValidator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

protocol ExpressTransactionValidator {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws
}
