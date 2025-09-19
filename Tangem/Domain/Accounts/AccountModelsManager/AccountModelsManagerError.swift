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
    case cannotFetchArchivedCryptoAccounts
    case cannotArchiveCryptoAccount
    case cannotUnarchiveCryptoAccount
}
