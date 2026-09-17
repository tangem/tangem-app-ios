//
//  CollectiblesOnboarder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Brings the collectibles account to its working state end to end: the cold key, the hot delegate, the
/// vault, the account it receives USDC on, and the delegate the vault names. Idempotent — whatever is
/// already in place is left alone, so this is also the retry after an interrupted run.
protocol CollectiblesOnboarder: AnyObject {
    func onboard() async throws
}
