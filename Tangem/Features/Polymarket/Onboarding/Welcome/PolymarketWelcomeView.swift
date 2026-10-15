//
//  PolymarketWelcomeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

struct PolymarketWelcomeView: View {
    @ObservedObject var viewModel: PolymarketWelcomeViewModel

    @State private var containerWidth: CGFloat = 0

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                hero

                title

                highlights

                questions
            }
        }
        .coordinateSpace(name: Constants.scrollSpace)
        .readGeometry(\.size.width) { containerWidth = $0 }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topTrailing) {
            closeButton
                .animation(.default, value: viewModel.isRunning)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .disabled(viewModel.isRunning)
        .alert(item: $viewModel.alert) { $0.alert }
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

    // MARK: - Hero

    private var hero: some View {
        GeometryReader { proxy in
            let overscroll = max(0, proxy.frame(in: .named(Constants.scrollSpace)).minY)
            let height = heroHeight(forWidth: proxy.size.width)

            Assets.Polymarket.welcomeBackground.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: proxy.size.width, height: height + overscroll)
                .clipped()
                .overlay { heroTint }
                .offset(y: -overscroll)
                .accessibilityHidden(true)
        }
        .aspectRatio(Constants.heroAspectRatio, contentMode: .fit)
        .padding(.bottom, -heroContentOverlap(forWidth: containerWidth))
    }

    private var heroTint: some View {
        LinearGradient(
            stops: [
                .init(color: DesignSystem.Color.bgPrimary.opacity(0), location: Constants.heroTintStart),
                .init(color: DesignSystem.Color.bgPrimary, location: Constants.heroTintEnd),
                .init(color: DesignSystem.Color.bgPrimary, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func heroHeight(forWidth width: CGFloat) -> CGFloat {
        width / Constants.heroAspectRatio
    }

    private func heroContentOverlap(forWidth width: CGFloat) -> CGFloat {
        heroHeight(forWidth: width) * Constants.heroContentOverlapRatio
    }

    // MARK: - Content

    private var title: some View {
        VStack(alignment: .leading, spacing: Constants.titleSpacing) {
            Text(viewModel.copy.title)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

            Text(viewModel.copy.subtitle)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.titleVerticalPadding)
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
            ForEach(Array(viewModel.copy.questions.enumerated()), id: \.element.id) { index, question in
                questionSection(question, isFirst: index == 0)
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
    }

    private func questionSection(_ question: PolymarketWelcomeContent.Question, isFirst: Bool) -> some View {
        VStack(alignment: .leading, spacing: Constants.questionSpacing) {
            Text(question.title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            Text(question.answer)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Constants.questionTopPadding)
        .padding(.bottom, Constants.questionSpacing)
        .overlay(alignment: .top) {
            if !isFirst {
                Separator(height: .minimal, color: DesignSystem.Color.borderSecondary)
            }
        }
        .padding(.top, isFirst ? 0 : Constants.questionSpacing)
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
        }
    }
}

// MARK: - Constants

private extension PolymarketWelcomeView {
    enum Constants {
        static let horizontalPadding: CGFloat = 24
        static let navigationHorizontalPadding: CGFloat = 16
        static let scrollSpace = "polymarketWelcomeScroll"

        static let heroAspectRatio: CGFloat = 402.0 / 608.0
        static let heroTintStart: CGFloat = 380.0 / 608.0
        static let heroTintEnd: CGFloat = 600.0 / 608.0
        static let heroContentOverlapRatio: CGFloat = (608.0 - 495.0) / 608.0

        static let titleSpacing: CGFloat = 8
        static let titleVerticalPadding: CGFloat = 12

        static let highlightSpacing: CGFloat = 8
        static let highlightPadding: CGFloat = 16
        static let highlightTrailingPadding: CGFloat = 24
        static let highlightCornerRadius: CGFloat = 24
        static let highlightContentHeight: CGFloat = 100
        static let highlightIconSize: CGFloat = 24
        static let highlightIconSpacing: CGFloat = 12

        static let questionSpacing: CGFloat = 12
        static let questionTopPadding: CGFloat = 24

        static let footerSpacing: CGFloat = 12
        static let footerVerticalPadding: CGFloat = 12
        static let footerFadeOverhang: CGFloat = 16
    }
}
