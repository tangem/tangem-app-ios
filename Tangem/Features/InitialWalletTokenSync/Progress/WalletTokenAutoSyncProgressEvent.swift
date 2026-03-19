//
//  WalletTokenAutoSyncProgressEvent.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum WalletTokenAutoSyncProgressEvent: Hashable {
    case inProgress(percent: Int)
    case completed
    case failed
}
