//
//  MoralisTokenBalanceClient+InjectedValues.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension InjectedValues {
    var moralisTokenBalanceClient: MoralisTokenBalanceClient {
        get { Self[MoralisTokenBalanceClientKey.self] }
        set { Self[MoralisTokenBalanceClientKey.self] = newValue }
    }
}

// MARK: - Private implementation

private struct MoralisTokenBalanceClientKey: InjectionKey {
    static var currentValue: MoralisTokenBalanceClient = CommonMoralisTokenBalanceClient()
}
