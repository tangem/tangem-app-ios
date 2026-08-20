//
//  WelcomeV2ActionSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct WelcomeV2ActionSheetView: View {
    @ObservedObject var viewModel: WelcomeV2ActionSheetViewModel

    var body: some View {
        FloatingSheetContentWithHeader(
            headerConfig: .init(
                title: viewModel.title,
                backAction: viewModel.onBack,
                closeAction: viewModel.onClose
            )
        ) {
            VStack(spacing: 12) {
                if let subtitle = viewModel.subtitle {
                    Text(subtitle)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                }

                VStack(spacing: 8) {
                    ForEach(viewModel.items) { item in
                        row(for: item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .floatingSheetConfiguration { config in
            config.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    @ViewBuilder
    private func row(for item: WelcomeV2ActionSheetItem) -> some View {
        Row(title: item.title, subtitle: item.subtitle)
            .contentLead(.start)
            .start(icon: item.icon)
            .end { endAccessory(for: item.state) }
            .onTap(item.action)
            .disabled(item.state != .enabled)
            .background(DesignSystem.Color.bgSecondary)
            .cornerRadiusContinuous(14)
    }

    @ViewBuilder
    private func endAccessory(for state: WelcomeV2ActionSheetItem.State) -> some View {
        switch state {
        case .enabled:
            DesignSystem.Icons.ChevronRight.regular16.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
        case .loading:
            Loader()
                .loaderSize(.size20)
                .loaderColor(DesignSystem.Color.iconSecondary)
        case .disabled:
            EmptyView()
        }
    }
}
