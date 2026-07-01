//
//  P2PBatchBalancesService+Injected.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

private struct P2PBatchBalancesServiceKey: InjectionKey {
    static var currentValue: P2PBatchBalancesService = StakingDependenciesFactory().makeP2PBatchBalancesService()
}

extension InjectedValues {
    var p2pBatchBalancesService: P2PBatchBalancesService {
        get { Self[P2PBatchBalancesServiceKey.self] }
        set { Self[P2PBatchBalancesServiceKey.self] = newValue }
    }
}
