//
//  TangemPayExpressProviderTransactionValidator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

struct TangemPayExpressProviderTransactionValidator: ExpressProviderTransactionValidator {
    func validateTransactionSize(data: String) -> Bool {
        return true
    }
}
