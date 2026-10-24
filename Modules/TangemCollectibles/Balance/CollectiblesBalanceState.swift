//
//  CollectiblesBalanceState.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMacro

@CaseFlagable
public enum CollectiblesBalanceState {
    case loading
    case loaded(UInt64)
    case failed(Error)
    /// No vault, so no account to hold anything — distinct from a balance of zero.
    case unavailable
}
