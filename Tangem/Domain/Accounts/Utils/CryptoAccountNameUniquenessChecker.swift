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
        let existingNames = remoteState
            .accounts
            .compactMap { $0.name?.trimmed() }
            + [Localization.accountMainAccountTitle]

        let trimmedAccountName = accountName.trimmed()

        return !existingNames.contains { existingName in
            return existingName.compare(trimmedAccountName) == .orderedSame
        }
    }
}
