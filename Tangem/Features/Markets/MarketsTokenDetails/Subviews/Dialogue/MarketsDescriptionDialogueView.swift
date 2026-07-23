//
//  MarketsDescriptionDialogueView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import MarkdownUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct MarketsDescriptionDialogueView: View {
    let viewModel: MarketsDescriptionDialogueViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                descriptionContent
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .floatingSheetConfiguration { config in
            config.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            config.backgroundInteractionBehavior = .tapToDismiss
            config.verticalSwipeBehavior = .init(target: .sheet, threshold: 100)
        }
    }
}

// MARK: - View Components

private extension MarketsDescriptionDialogueView {
    var header: some View {
        BottomSheetHeaderView(
            title: viewModel.title,
            trailing: {
                TangemUI.Button(
                    icon: DesignSystem.Icons.Cross.regular20,
                    accessibilityLabel: Localization.commonClose,
                    action: { viewModel.closeAction() }
                )
                .size(.x9)
                .styleType(.secondary)
            }
        )
        .titleFont(DesignSystem.Font.bodyMediumToken.font) // [REDACTED_INFO]: tracking deferred
        .titleColor(DesignSystem.Color.textPrimary)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .environment(\.isRedesign, true)
    }

    var descriptionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Markdown { viewModel.descriptionText }
                .markdownSoftBreakMode(.lineBreak)
                .markdownTextStyle(\.text, textStyle: {
                    FontFamily(.system())
                    FontWeight(.regular)
                    FontSize(16)
                    ForegroundColor(DesignSystem.Color.textSecondary)
                })
                .markdownBlockStyle(\.paragraph, body: { configuration in
                    configuration.label
                        .relativeLineSpacing(.em(0.2))
                })
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            if viewModel.showGeneratedWithAI {
                generatedWithAIBadge
            }
        }
    }

    var generatedWithAIBadge: some View {
        SwiftUI.Button {
            viewModel.onGenerateAITapAction?()
        } label: {
            HStack(spacing: 12) {
                Assets.stars.image
                    .foregroundStyle(DesignSystem.Color.iconAccentBlue)

                Text(Localization.informationGeneratedWithAi)
                    .multilineTextAlignment(.leading)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .defaultRoundedBackground(with: DesignSystem.Color.bgTertiary)
        }
        .disabled(viewModel.onGenerateAITapAction == nil)
    }
}
