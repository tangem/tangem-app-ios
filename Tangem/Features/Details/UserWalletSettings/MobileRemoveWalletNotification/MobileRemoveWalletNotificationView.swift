//
//  MobileRemoveWalletNotificationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MobileRemoveWalletNotificationView: View {
    @ObservedObject var viewModel: MobileRemoveWalletNotificationViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            content
                .padding(.top, 8)
                .padding(.horizontal, 16)

            footer
                .padding(.top, 40)
        }
        .padding(16)
        .background(Colors.Background.primary)
        .alert(item: $viewModel.alert) { $0.alert }
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}

// MARK: - Subviews

private extension MobileRemoveWalletNotificationView {
    var header: some View {
        NavigationBarButton.close(action: viewModel.onCloseTap)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var content: some View {
        VStack(spacing: 0) {
            warningIcon

            Text(viewModel.title)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .padding(.top, 24)

            Text(viewModel.description)
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var warningIcon: some View {
        ZStack {
            Circle()
                .fill(Colors.Text.warning.opacity(0.1))
                .frame(width: 56, height: 56)

            Assets.redCircleWarning.image
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Colors.Text.warning)
                .frame(width: 30, height: 30)
                .background {
                    Circle()
                        .fill(Colors.Text.constantWhite)
                        .padding(4)
                }
        }
    }

    var footer: some View {
        VStack(spacing: 8) {
            MainButton(
                title: viewModel.removeAction.title,
                style: .secondary,
                action: viewModel.removeAction.handler
            )

            MainButton(
                title: viewModel.backupAction.title,
                style: .primary,
                action: viewModel.backupAction.handler
            )
        }
    }
}
