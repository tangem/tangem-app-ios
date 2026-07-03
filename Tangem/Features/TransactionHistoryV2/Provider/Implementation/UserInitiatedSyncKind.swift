//
//  UserInitiatedSyncKind.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum UserInitiatedSyncKind: Sendable, Hashable {
    case pullToRefresh
    case postBroadcast
}
