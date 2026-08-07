//
//  MainNavigationBalanceView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct MainNavigationBalanceView: View {
    let state: MainNavigationBalanceState

    var body: some View {
        switch state {
        case .loading(.some(let text)), .loaded(let text):
            SensitiveText(text)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

        case .loading(.none), .empty:
            EmptyView()
        }
    }
}
