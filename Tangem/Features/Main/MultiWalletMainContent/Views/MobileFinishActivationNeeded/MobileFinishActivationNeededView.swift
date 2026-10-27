//
//  MobileFinishActivationNeededView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MobileFinishActivationNeededView: View {
    let viewModel: MobileFinishActivationNeededViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            content
                .padding(.top, 4)
                .padding(.horizontal, 16)

            footer
                .padding(.top, 46)
        }
        .padding(16)
        .background(DesignSystem.Color.bgPrimary)
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}

// MARK: - Subviews

private extension MobileFinishActivationNeededView {
    var header: some View {
        NavigationBarButton.close(action: viewModel.onCloseTap)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var content: some View {
        VStack(spacing: 0) {
            attentionIcon

            Text(viewModel.title)
                .style(Fonts.Bold.title3, color: DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 24)

            Text(viewModel.description)
                .style(Fonts.Regular.subheadline, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var attentionIcon: some View {
        ZStack {
            Circle()
                .fill(viewModel.iconBgColor)
                .frame(width: 56, height: 56)

            viewModel.iconType.image
                .resizable()
                .renderingMode(.original)
                .frame(width: 26, height: 29)
        }
    }

    var footer: some View {
        VStack(spacing: 8) {
            MainButton(
                title: viewModel.laterTitle,
                style: .secondary,
                action: viewModel.onLaterTap
            )

            MainButton(
                title: viewModel.backupTitle,
                action: viewModel.onBackupTap
            )
        }
    }
}
