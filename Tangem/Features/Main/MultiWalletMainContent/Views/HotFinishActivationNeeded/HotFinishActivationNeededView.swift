//
//  HotFinishActivationNeededView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct HotFinishActivationNeededView: View {
    let viewModel: HotFinishActivationNeededViewModel

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
        .background(Colors.Background.primary)
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}

// MARK: - Subviews

private extension HotFinishActivationNeededView {
    var header: some View {
        CircleButton.close(action: viewModel.onCloseTap)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var content: some View {
        VStack(spacing: 0) {
            attentionIcon

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

    var attentionIcon: some View {
        ZStack {
            Circle()
                .fill(Colors.Icon.warning.opacity(0.1))
                .frame(width: 56, height: 56)

            Assets.criticalAttentionShield.image
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
