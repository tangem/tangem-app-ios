//
//  TransactionHistoryRecordsWriteResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

protocol TransactionHistoryRecordsWriteResolver: Sendable {
    func write(in database: Database) throws
}
