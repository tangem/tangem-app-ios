//
//  MobileBackupToUpgradeNeededView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MobileBackupToUpgradeNeededView: View {
    let viewModel: MobileBackupToUpgradeNeededViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            info
                .padding(.top, 28)
                .padding(.horizontal, 16)

            footer
                .padding(.top, 72)
        }
        .padding(16)
        .background(Colors.Background.primary)
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}

// MARK: - Subviews

private extension MobileBackupToUpgradeNeededView {
    var header: some View {
        NavigationBarButton.close(action: viewModel.onCloseTap)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var info: some View {
        VStack(spacing: 0) {
            Assets.lockedRefresh.image
                .resizable()
                .renderingMode(.original)
                .frame(width: 56, height: 56)

            Text(viewModel.title)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 24)

            Text(viewModel.description)
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var footer: some View {
        MainButton(
            title: viewModel.actionTitle,
            action: viewModel.onBackupTap
        )
    }
}
