//
//  AccountRecoveryError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum AccountRecoveryError: Error {
    case tooManyAccounts
    case duplicateAccountName
    case unknownError(Error)
}
