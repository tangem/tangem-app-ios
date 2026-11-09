//
//  BlockchainAccountInitializationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct BlockchainAccountInitializationView: View {
    @ObservedObject var viewModel: BlockchainAccountInitializationViewModel

    var body: some View {
        VStack {
            BottomSheetHeaderView(
                title: "",
                trailing: {
                    NavigationBarButton.close(action: viewModel.dismiss)
                }
            )

            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: CGSize(width: 56, height: 56),
                forceKingfisher: false
            )

            VStack(spacing: 14) {
                Text(Localization.stakingAccountInitializationTitle)
                    .style(Fonts.Bold.title2, color: DesignSystem.Color.textPrimary)
                Text(Localization.stakingAccountInitializationMessage)
                    .style(Fonts.Regular.subheadline, color: DesignSystem.Color.textSecondary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)

            VStack(spacing: 24) {
                GroupedSection(viewModel.feeRowViewModel) {
                    DefaultRowView(viewModel: $0)
                } footer: {
                    DefaultFooterView(Localization.stakingAccountInitializationFooter)
                }
                .backgroundColor(DesignSystem.Color.bgSecondary)

                SigningActionButtonView(
                    type: viewModel.signingActionButtonType,
                    title: Localization.commonActivate,
                    isLoading: viewModel.isLoading,
                    isDisabled: false,
                    action: viewModel.initializeAccount
                )
            }
            .padding(.vertical, 16)
        }
        .padding(.horizontal, 16)
        .background(DesignSystem.Color.bgPrimary)
        .onAppear {
            viewModel.onAppear()
        }
    }
}
