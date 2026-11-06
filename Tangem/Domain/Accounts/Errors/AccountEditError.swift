//
//  AccountEditError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemMacro

@RawCaseName
enum AccountEditError: Error {
    case tooManyAccounts
    case invalidAccountName
    case missingAccountName
    case duplicateAccountName
    case unknownError(Error)
}
