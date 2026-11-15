//
//  SelectorBalance.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

public enum SelectorBalance: Hashable {
    case loading(cached: String?)
    case loaded(String)
    case failed(String)
}

struct SelectorBalanceText: View {
    let balance: SelectorBalance
    let isMasked: Bool

    var body: some View {
        switch balance {
        case .loading(.none):
            Shimmer()
                .variant(.text(style: .caption))
                .frame(width: 72)

        case .loading(.some(let cached)):
            UtilBalance(cached)
                .masked(isMasked)
                .updating()
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

        case .loaded(let text), .failed(let text):
            UtilBalance(text)
                .masked(isMasked)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
    }
}
