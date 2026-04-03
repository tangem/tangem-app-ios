//
//  WalletTokenAutoSyncError.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum WalletTokenAutoSyncError: Error {
    case syncAlreadyInProgress
    case userTokenListNotReady
}
