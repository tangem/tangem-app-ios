//
//  MainNavigationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MainNavigationView: View {
    @ObservedObject var viewModel: MainNavigationViewModel

    var body: some View {
        MainNavigationBalanceView(
            state: viewModel.balance,
            style: .init(font: .Tangem.Body16.semibold, textColor: .Tangem.Text.Neutral.primary)
        )
    }
}
