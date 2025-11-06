//
//  AccountModelsManagerError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum AccountModelsManagerError: Error {
    case addingCryptoAccountsNotSupported
    case addingCryptoAccountsFailed
    case cannotFetchArchivedCryptoAccounts
}

enum AccountArchivationError: Error {
    case participatesInReferralProgram
    case unknownError(Error)
}

enum AccountRecoveryError: Error {
    case tooManyActiveAccounts
    case unknownError(Error)
}
