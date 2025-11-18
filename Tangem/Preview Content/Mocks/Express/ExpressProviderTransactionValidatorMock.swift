//
//  ExpressProviderTransactionValidatorMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct ExpressProviderTransactionValidatorMock: ExpressProviderTransactionValidator {
    func validateTransactionSize(data: String?) -> Bool {
        return true
    }
}
