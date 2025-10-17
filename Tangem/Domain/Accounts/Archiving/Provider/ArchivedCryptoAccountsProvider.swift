//
//  ArchivedCryptoAccountsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol ArchivedCryptoAccountsProvider {
    func getArchivedCryptoAccounts() async throws -> [ArchivedCryptoAccountInfo]
}
