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
                    .padding(.horizontal, .unit(.x4))
                    .padding(.bottom, .unit(.x4))
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .floatingSheetConfiguration { config in
            config.sheetBackgroundColor = Color.Tangem.Surface.level3
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
                TangemButton(content: .icon(Assets.Glyphs.cross20ButtonNew)) {
                    viewModel.closeAction()
                }
                .setStyleType(.secondary)
                .setSize(.x9)
                .setHorizontalLayout(.intrinsic)
            }
        )
        .titleFont(Font.Tangem.Heading17.semibold.font) // [REDACTED_INFO]: tracking deferred
        .titleColor(Color.Tangem.Text.Neutral.primary)
        .padding(.horizontal, .unit(.x4))
        .padding(.top, .unit(.x3))
        .environment(\.isRedesign, FeatureProvider.isAvailable(.redesign))
    }

    var descriptionContent: some View {
        VStack(alignment: .leading, spacing: .unit(.x3)) {
            Markdown { viewModel.descriptionText }
                .markdownSoftBreakMode(.lineBreak)
                .markdownTextStyle(\.text, textStyle: {
                    FontFamily(.system())
                    FontWeight(.regular)
                    FontSize(16)
                    ForegroundColor(Color.Tangem.Text.Neutral.tertiary)
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
        Button {
            viewModel.onGenerateAITapAction?()
        } label: {
            HStack(spacing: .unit(.x3)) {
                Assets.stars.image
                    .foregroundStyle(Color.Tangem.Graphic.Status.accent)

                Text(Localization.informationGeneratedWithAi)
                    .multilineTextAlignment(.leading)
                    .style(Font.Tangem.Caption13.regular, color: Color.Tangem.Text.Neutral.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .defaultRoundedBackground(with: Color.Tangem.Surface.level4)
        }
        .disabled(viewModel.onGenerateAITapAction == nil)
    }
}
