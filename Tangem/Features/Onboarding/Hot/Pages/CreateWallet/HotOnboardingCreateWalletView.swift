//
//  HotOnboardingCreateWalletView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct HotOnboardingCreateWalletView: View {
    typealias ViewModel = HotOnboardingCreateWalletViewModel

    let viewModel: ViewModel

    var body: some View {
        VStack(spacing: 0) {
            Assets.MobileWallet.mobileWallet.image

            Text(viewModel.title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .padding(.horizontal, 24)
                .padding(.top, 20)

            VStack(spacing: 28) {
                ForEach(viewModel.infoItems) {
                    infoItem($0)
                }
            }
            .padding(.top, 32)

            Spacer()

            MainButton(
                title: viewModel.createButtonTitle,
                action: viewModel.onCreateTap
            )
        }
        .padding(.top, 64)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}

// MARK: - Subviews

private extension HotOnboardingCreateWalletView {
    func infoItem(_ item: ViewModel.InfoItem) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Colors.Control.unchecked)
                    .frame(width: 42)

                item.icon.image
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .style(Fonts.Bold.callout, color: Colors.Icon.primary1)

                Text(item.subtitle)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 32)
    }
}
