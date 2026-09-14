//
//  AccountModelsManagerError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum AccountModelsManagerError: Error {
    case addingJointAccountNotSupported
    case addingCryptoAccountsNotSupported
    case cannotFetchArchivedCryptoAccounts
    /// Activation was asked for on an account that has no address to confirm yet, or no creator among its members —
    /// the screen only offers it once both hold, so this is a programming error rather than a state a user reaches.
    case jointAccountNotReadyForActivation
}
