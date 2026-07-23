//
//  WalletConnectRedesignedRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccessibilityIdentifiers

struct WalletConnectRedesignedRowView: View {
    private let viewModel: WalletConnectRowViewModel

    init(viewModel: WalletConnectRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        TangemRow(title: viewModel.title, subtitle: viewModel.subtitle)
            .start {
                Assets.walletConnect.image
                    .resizable()
                    .frame(width: 36, height: 36)
            }
            .end(icon: DesignSystem.Icons.ChevronRight.regular20)
            .onTap(viewModel.action)
            .accessibilityIdentifier(WalletConnectAccessibilityIdentifiers.detailsButton)
    }
}
