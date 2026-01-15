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

    init(viewModel: BlockchainAccountInitializationViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            BottomSheetHeaderView(
                title: "",
                trailing: {
                    CircleButton.close(action: viewModel.dismiss)
                }
            )

            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: CGSize(width: 56, height: 56),
                forceKingfisher: false
            )

            VStack(spacing: 14) {
                Text(Localization.stakingAccountInitializationTitle)
                    .style(Fonts.Bold.title2, color: Colors.Text.primary1)
                Text(Localization.stakingAccountInitializationMessage)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
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
                .backgroundColor(Colors.Background.action)

                MainButton(
                    title: Localization.commonActivate,
                    icon: viewModel.mainButtonIcon,
                    isLoading: viewModel.isLoading,
                    isDisabled: false,
                    action: viewModel.initializeAccount
                )
            }
            .padding(.vertical, 16)
        }
        .padding(.horizontal, 16)
        .background(Colors.Background.tertiary)
        .onAppear {
            viewModel.onAppear()
        }
    }
}
