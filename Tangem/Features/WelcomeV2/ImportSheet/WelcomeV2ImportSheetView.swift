//
//  WelcomeV2ImportSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct WelcomeV2ImportSheetView: View {
    @ObservedObject var viewModel: WelcomeV2ImportSheetViewModel

    var body: some View {
        FloatingSheetContentWithHeader(
            headerConfig: .init(
                title: "",
                backAction: viewModel.onBack,
                closeAction: viewModel.onClose
            )
        ) {
            VStack(spacing: 16) {
                badge

                titleBlock
                    .padding(.horizontal, 24)

                VStack(spacing: 8) {
                    ForEach(viewModel.items) { item in
                        row(for: item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
    }

    private var badge: some View {
        DesignSystem.Icons.ArrowDownload.regular24.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconAccentBlue)
            .frame(width: 60, height: 60)
            .background(DesignSystem.Color.bgAccentBlue, in: Circle())
            .accessibilityHidden(true)
    }

    private var titleBlock: some View {
        VStack(spacing: 4) {
            Text(viewModel.title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.center)

            if let subtitle = viewModel.subtitle {
                Text(subtitle)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func row(for item: WelcomeV2ImportSheetItem) -> some View {
        Button(action: item.action) {
            Text(item.title)
                .style(
                    DesignSystem.Font.subheadingMediumToken,
                    color: item.isEnabled ? DesignSystem.Color.textPrimary : DesignSystem.Color.textSecondary
                )
                .frame(maxWidth: .infinity, minHeight: 52)
                .overlay(alignment: .trailing) {
                    if item.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 16)
                    }
                }
                .background(DesignSystem.Color.bgSecondary)
                .cornerRadiusContinuous(14)
        }
        .disabled(!item.isEnabled)
    }
}
