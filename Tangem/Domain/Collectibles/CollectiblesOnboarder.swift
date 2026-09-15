//
//  CollectiblesOnboarder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Creates the collectibles account end to end: derives the cold key and deploys the vault on chain.
/// Idempotent — a vault that already exists on chain is a no-op.
protocol CollectiblesOnboarder: AnyObject {
    func onboard() async throws
}
