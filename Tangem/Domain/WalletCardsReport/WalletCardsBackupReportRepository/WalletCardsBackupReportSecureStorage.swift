//
//  WalletCardsBackupReportSecureStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol WalletCardsBackupReportSecureStorage {
    func get(_ account: String) throws -> Data?
    func store(_ object: Data, forKey account: String, overwrite: Bool) throws
}

extension SecureStorage: WalletCardsBackupReportSecureStorage {}
