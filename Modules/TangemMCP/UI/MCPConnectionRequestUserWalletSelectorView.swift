//
//  MCPConnectionRequestUserWalletSelectorView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct MCPConnectionRequestUserWalletSelectorView: View {
    @ObservedObject var viewModel: MCPConnectionRequestUserWalletSelectorViewModel

    var body: some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.state.userWallets) { rowViewModel in
                MCPConnectionRequestUserWalletSelectorRowView(viewModel: rowViewModel)
            }
        }
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
