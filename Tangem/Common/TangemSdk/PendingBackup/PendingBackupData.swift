//
//  PendingBackupData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PendingBackup: Codable {
    var cards: [String: PendingBackupCard]
}

struct PendingBackupCard: Codable {
    let hasWalletsError: Bool
    let hasBackupError: Bool
}
