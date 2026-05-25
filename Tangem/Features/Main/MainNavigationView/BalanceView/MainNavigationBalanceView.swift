//
//  MainNavigationBalanceView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MainNavigationBalanceView: View {
    let state: MainNavigationBalanceState

    var body: some View {
        switch state {
        case .loading(.some(let text)), .loaded(let text):
            SensitiveText(text)
                .style(Font.Tangem.Body16.semibold, color: Color.Tangem.Text.Neutral.primary)

        case .loading(.none), .empty:
            EmptyView()
        }
    }
}
