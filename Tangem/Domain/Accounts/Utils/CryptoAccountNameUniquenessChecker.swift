//
//  CryptoAccountNameUniquenessChecker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct CryptoAccountNameUniquenessChecker {
    private let remoteState: CryptoAccountsRemoteState

    init(remoteState: CryptoAccountsRemoteState) {
        self.remoteState = remoteState
    }

    func isNameUnique(_ accountName: String) -> Bool {
        let existingNames = existingNames(from: remoteState)
        let trimmedAccountName = accountName.trimmed()

        return !existingNames.contains { existingName in
            return existingName.compare(trimmedAccountName) == .orderedSame
        }
    }

    private func existingNames(from remoteState: CryptoAccountsRemoteState) -> [String] {
        var existingNames = remoteState
            .accounts
            .compactMap { $0.name?.trimmed() }

        // Default localized name for main accounts should be considered only if it is actually used
        if remoteState.accounts.contains(where: { $0.name == nil }) {
            existingNames.append(Localization.accountMainAccountTitle)
        }

        return existingNames
    }
}
