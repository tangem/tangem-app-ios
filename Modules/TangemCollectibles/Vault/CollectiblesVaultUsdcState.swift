//
//  CollectiblesVaultUsdcState.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemMacro

@CaseFlagable
public enum CollectiblesVaultUsdcState: Hashable, Sendable {
    case loading
    case missing
    case ready(CollectiblesVaultUsdcAccount)
    case failed
}
