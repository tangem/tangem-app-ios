//
//  AccountEditError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum AccountEditError: Error {
    case tooManyAccounts
    case accountNameTooLong
    case missingAccountName
    case duplicateAccountName
    case unknownError(Error)
}
