//
//  WelcomeHardwareWalletView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

// [REDACTED_TODO_COMMENT]
struct WelcomeHardwareWalletView: View {
    @ObservedObject var viewModel: WelcomeHardwareWalletViewModel

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer()

                titleBlock
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)

                buttons
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .alert(item: $viewModel.alert, content: { $0.alert })
        .fullScreenCover(item: $viewModel.shopWebViewModel) { webViewModel in
            WebViewContainer(viewModel: webViewModel)
                .environment(\.colorScheme, .dark)
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()

            TangemUI.Button(
                icon: DesignSystem.Icons.Cross.regular16,
                accessibilityLabel: "Close",
                action: viewModel.onCloseTap
            )
            .styleType(.secondary)
            .size(.x8)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("One wallet, multiple cards")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)

            Text("Use any of your cards to access your wallet")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            TangemUI.Button(
                label: "Learn more or buy",
                accessibilityLabel: nil,
                action: viewModel.onLearnMoreTap
            )
            .styleType(.secondary)
            .horizontalLayout(.infinity)
            .size(.x14)
            .disabled(viewModel.isScanning)

            TangemUI.Button(
                label: "Scan your wallet",
                accessibilityLabel: nil,
                action: viewModel.onScanTap
            )
            .styleType(.default)
            .horizontalLayout(.infinity)
            .size(.x14)
            .iconEnd(Assets.tangemIcon)
            .disabled(viewModel.isScanning)
        }
    }
}
