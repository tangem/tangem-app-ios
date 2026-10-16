//
//  CollectiblesAccountExpressProviderTransactionValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

struct CollectiblesAccountExpressProviderTransactionValidator: ExpressProviderTransactionValidator {
    func validateTransactionSize(data: String) -> Bool {
        true
    }
}
