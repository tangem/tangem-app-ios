//
//  RedesignActionButtonsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct RedesignActionButtonsView: View {
    @ObservedObject var viewModel: ActionButtonsViewModel

    var body: some View {
        HStack(spacing: SizeUnit.x6.value) {
            RedesignActionButtonView(viewModel: viewModel.buyActionButtonViewModel)

            RedesignActionButtonView(viewModel: viewModel.swapActionButtonViewModel)

            RedesignActionButtonView(viewModel: viewModel.sellActionButtonViewModel)
        }
    }
}
