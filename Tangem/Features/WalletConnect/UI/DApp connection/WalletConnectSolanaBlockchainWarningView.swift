//
//  WalletConnectSolanaBlockchainWarningView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct WalletConnectSolanaBlockchainWarningView: View {
    @ObservedObject var viewModel: WalletConnectSolanaBlockchainWarningViewModel

    var body: some View {
        VStack(spacing: 24) {
            viewModel.state.iconAsset.image
                .resizable()
                .frame(width: 56, height: 56)

            VStack(spacing: 8) {
                Text(viewModel.state.title)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                Text(viewModel.state.body)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .padding(.bottom, 24)
        .padding(.horizontal, 32)
    }
}
