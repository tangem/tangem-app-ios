//
//  AddressBookSyncState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Drives sync-related UI (spinner, offline banner, error state) with no logic on the view side.
enum AddressBookSyncState: Hashable {
    case syncing
    case synced
    case offline
    case failed
}
