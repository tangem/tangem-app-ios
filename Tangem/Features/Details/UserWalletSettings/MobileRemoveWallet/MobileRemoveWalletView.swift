//
//  MobileRemoveWalletView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MobileRemoveWalletView: View {
    typealias ViewModel = MobileRemoveWalletViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
            .navigationTitle(viewModel.navigationTitle)
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
            .background(Colors.Background.primary)
    }
}

// MARK: - Subviews

private extension MobileRemoveWalletView {
    var content: some View {
        VStack(spacing: 0) {
            Spacer()

            attention(item: viewModel.attentionItem)
                .padding(.top, 12)
                .padding(.horizontal, 24)

            Spacer()

            marks
                .padding(.horizontal, 8)

            action(item: viewModel.actionItem)
                .padding(.top, 24)
        }
    }

    func attention(item: ViewModel.AttentionItem) -> some View {
        VStack(spacing: 0) {
            item.icon.image
                .resizable()
                .frame(width: 72, height: 72)

            Text(item.title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .padding(.top, 20)

            Text(item.subtitle)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var marks: some View {
        MobileRemoveWalletCheckmarkRow(title: viewModel.backupInfo, isChecked: $viewModel.isBackupChecked)
    }

    func action(item: ViewModel.ActionItem) -> some View {
        MainButton(
            title: item.title,
            style: .primary,
            isDisabled: !viewModel.isActionEnabled,
            action: item.action
        )
        .confirmationDialog(viewModel: $viewModel.confirmationDialog)
    }
}
