//
//  TangemPayFailedToIssueCardSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TangemPayFailedToIssueCardSheetView: View {
    let viewModel: TangemPayFailedToIssueCardSheetViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content

            NavigationBarButton.close(action: viewModel.close)
                .padding(.all, 16)
        }
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    var content: some View {
        VStack(spacing: .zero) {
            VStack(spacing: 24) {
                Assets.redCircleWarning20Outline.image
                    .resizable()
                    .frame(width: 32, height: 32)
                    .padding(12)
                    .background(Circle().fill(Colors.Icon.warning.opacity(0.1)))

                VStack(spacing: 12) {
                    Text(viewModel.title)
                        .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(viewModel.subtitle)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.center)
            }
            .padding(.vertical, 50)
            .padding(.horizontal, 16)

            MainButton(settings: viewModel.primaryButtonSettings)
                .padding(.all, 16)
        }
        .infinityFrame(axis: .horizontal)
    }
}
