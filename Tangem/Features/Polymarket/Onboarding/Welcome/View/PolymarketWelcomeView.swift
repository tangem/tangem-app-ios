//
//  PolymarketWelcomeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

struct PolymarketWelcomeView: View {
    @ObservedObject var viewModel: PolymarketWelcomeViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                PolymarketHero(image: Assets.Polymarket.welcomeBackground, tint: Constants.heroTint, scrollSpace: Constants.scrollSpace)

                title

                highlights

                questions
            }
        }
        .coordinateSpace(name: Constants.scrollSpace)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topTrailing) {
            closeButton
                .animation(.default, value: viewModel.isRunning)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .disabled(viewModel.isRunning)
        .alert(item: $viewModel.alert) { $0.alert }
        .modal(
            isPresented: $viewModel.isFastTradingFAQPresented,
            size: .full,
            navigation: .title(PolymarketFastTradingStrings.title),
            content: { PolymarketFastTradingFAQView() }
        )
    }

    @ViewBuilder
    private var closeButton: some View {
        if !viewModel.isRunning {
            NavigationBarButton.close { viewModel.handleViewAction(.close) }
                .redesigned()
                .padding(.trailing, Constants.navigationHorizontalPadding)
                .transition(.opacity)
        }
    }

    // MARK: - Content

    private var title: some View {
        VStack(alignment: .leading, spacing: Constants.titleSpacing) {
            Text(viewModel.copy.title)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                .accessibilityIdentifier(PolymarketAccessibilityIdentifiers.onboardingTitle)

            if viewModel.showsFastTradingToggle {
                fastTradingCard
                    .padding(.vertical, Constants.fastTradingCardVerticalPadding)
            }

            Text(viewModel.copy.subtitle)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.titleVerticalPadding)
    }

    private var fastTradingCard: some View {
        VStack(alignment: .leading, spacing: Constants.fastTradingCardSpacing) {
            SwiftUI.Button(action: { viewModel.handleViewAction(.openFastTradingFAQ) }) {
                HStack(spacing: Constants.fastTradingCaptionSpacing) {
                    Text(PolymarketFastTradingStrings.title)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

                    DesignSystem.Icons.Info.regular16.image
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconSecondary)
                }
                .expandingHitArea(by: Constants.fastTradingInfoHitAreaInset)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(PolymarketFastTradingStrings.whatIsFastTrading)

            Toggle(isOn: $viewModel.isFastTradingEnabled) {
                Text(PolymarketFastTradingStrings.onboardingToggleTitle)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .tint(DesignSystem.Color.bgStatusInfo)
        }
        .padding(Constants.fastTradingCardPadding)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(.rect(cornerRadius: Constants.fastTradingCardCornerRadius))
        .glowRing(.magic)
    }

    private var highlights: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Constants.highlightSpacing),
                GridItem(.flexible(), spacing: Constants.highlightSpacing),
            ],
            alignment: .leading,
            spacing: Constants.highlightSpacing
        ) {
            ForEach(viewModel.copy.highlights) { highlightCard($0) }
        }
        .padding(Constants.horizontalPadding)
    }

    private func highlightCard(_ highlight: PolymarketWelcomeContent.Highlight) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            highlight.icon.image
                .renderingMode(.template)
                .resizable()
                .frame(width: Constants.highlightIconSize, height: Constants.highlightIconSize)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
                .accessibilityHidden(true)

            Spacer(minLength: Constants.highlightIconSpacing)

            VStack(alignment: .leading, spacing: 0) {
                Text(highlight.title)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)

                Text(highlight.subtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: Constants.highlightContentHeight)
        .padding(.leading, Constants.highlightPadding)
        .padding(.trailing, Constants.highlightTrailingPadding)
        .padding(.vertical, Constants.highlightPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(.rect(cornerRadius: Constants.highlightCornerRadius))
    }

    private var questions: some View {
        VStack(spacing: 0) {
            ForEach(indexed: viewModel.copy.questions) { index, question in
                PolymarketTextSection(title: question.title, text: question.answer, isSeparated: index > 0)
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: Constants.footerSpacing) {
            PolymarketLegalLine(notice: viewModel.copy.legalNotice, onTermsTap: { viewModel.handleViewAction(.openLegalTerms($0)) })

            actionButton
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.footerVerticalPadding)
        .background {
            Fade(position: .bottom)
                .variant(.hard)
                .blurred()
                .padding(.top, -Constants.footerFadeOverhang)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if let stageMessage = viewModel.stageMessage {
            TangemUI.Button(label: viewModel.copy.actionTitle, accessibilityLabel: nil, action: {})
                .styleType(.primary)
                .size(.x12)
                .horizontalLayout(.infinity)
                .loading(.spinnerWithMessage(stageMessage))
        } else {
            SigningActionButtonView(
                type: viewModel.signingButtonType,
                title: viewModel.copy.actionTitle,
                isLoading: false,
                isDisabled: false,
                action: { viewModel.handleViewAction(.startOnboarding) }
            )
            .accessibilityIdentifier(PolymarketAccessibilityIdentifiers.onboardingActionButton)
        }
    }
}

// MARK: - Constants

private extension PolymarketWelcomeView {
    enum Constants {
        static let horizontalPadding: CGFloat = 24
        static let navigationHorizontalPadding: CGFloat = 16
        static let scrollSpace = "polymarketWelcomeScroll"

        static let heroTint = PolymarketHero.Tint(start: 380.0 / 608.0, end: 600.0 / 608.0)

        static let titleSpacing: CGFloat = 8
        static let titleVerticalPadding: CGFloat = 12

        static let fastTradingCardVerticalPadding: CGFloat = 8
        static let fastTradingCardSpacing: CGFloat = 8
        static let fastTradingCaptionSpacing: CGFloat = 2
        static let fastTradingInfoHitAreaInset: CGFloat = 14
        static let fastTradingCardPadding: CGFloat = 16
        static let fastTradingCardCornerRadius: CGFloat = 24

        static let highlightSpacing: CGFloat = 8
        static let highlightPadding: CGFloat = 16
        static let highlightTrailingPadding: CGFloat = 24
        static let highlightCornerRadius: CGFloat = 24
        static let highlightContentHeight: CGFloat = 100
        static let highlightIconSize: CGFloat = 24
        static let highlightIconSpacing: CGFloat = 12

        static let footerSpacing: CGFloat = 12
        static let footerVerticalPadding: CGFloat = 12
        static let footerFadeOverhang: CGFloat = 16
    }
}
