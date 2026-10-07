//
//  PolymarketEventDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

struct PolymarketEventDetailsView: View {
    @ObservedObject var viewModel: PolymarketEventDetailsViewModel

    @State private var barHeight: CGFloat = 0

    @State private var titleTransferProgress: CGFloat = 0

    @State private var headerTitleHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            topBar
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .background(FeedPopGestureEnabler())
        .onWillAppear { viewModel.handleViewAction(.onAppear) }
        .onWillDisappear { viewModel.handleViewAction(.onDisappear) }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: Constants.barSpacing) {
            backButton

            titleSlot
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Constants.toolbarHeight)
        .padding(.top, Constants.barTopPadding)
        .padding(.bottom, Constants.barBottomPadding)
        .readGeometry(\.size.height, bindTo: $barHeight)
        .background {
            Fade(position: .top)
                .blurred()
                .backgroundColor(DesignSystem.Color.bgPrimary)
                .ignoresSafeArea(edges: .top)
        }
    }

    private var backButton: some View {
        NavigationBarButton.back { viewModel.handleViewAction(.close) }
            .accessibilityLabel(Localization.commonBack)
    }

    @ViewBuilder
    private var titleSlot: some View {
        if case .content(let content) = viewModel.state {
            HStack(spacing: Constants.collapsedTitleSpacing) {
                PolymarketAvatarView(url: content.iconURL, side: Constants.barButtonSide)

                VStack(alignment: .leading, spacing: Constants.barSubtitleSpacing) {
                    Text(content.title)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .lineLimit(1)

                    if let categoryName = content.categoryName {
                        categoryBadge(categoryName)
                    }
                }
                .scaleEffect(barTitleScale, anchor: .leading)
                .opacity(barTitleOpacity)
                .accessibilityHidden(barTitleOpacity == 0)
                .animation(Constants.handoffAnimation, value: titleTransferProgress)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            PolymarketEventDetailsSkeletonView()
                .padding(.top, barHeight)

        case .failed(let failure):
            PolymarketEmptyMessageView(message: failure.message, onRetry: { viewModel.handleViewAction(.retry) })
                .frame(maxHeight: .infinity)

        case .content(let content):
            loadedContent(content)
        }
    }

    private func loadedContent(_ content: PolymarketEventDetailsContent) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                header(content)

                marketsSection(content)

                summarySection(content)
            }
            .readContentOffset(inCoordinateSpace: .named(Constants.scrollSpace)) { updateTitleTransfer(contentOffset: $0) }
        }
        .scrollBounceBehavior(.basedOnSize)
        .coordinateSpace(name: Constants.scrollSpace)
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: barHeight)
        }
    }

    // MARK: - Header

    private func header(_ content: PolymarketEventDetailsContent) -> some View {
        VStack(alignment: .leading, spacing: Constants.headerSpacing) {
            Text(content.title)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .scaleEffect(pageTitleScale, anchor: .topLeading)
                .offset(x: pageHandoffProgress * Constants.pageTitleTravelX)
                .readGeometry(\.size.height, bindTo: $headerTitleHeight)

            if content.hasMeta {
                metaRow(content)
            }
        }
        .opacity(pageContentOpacity)
        .accessibilityHidden(pageContentOpacity == 0)
        .animation(Constants.handoffAnimation, value: titleTransferProgress)
        .padding(.horizontal, Constants.textHorizontalPadding)
        .padding(.vertical, Constants.headerVerticalPadding)
    }

    private func metaRow(_ content: PolymarketEventDetailsContent) -> some View {
        WrappingHStack(
            alignment: .leading,
            horizontalSpacing: Constants.metaSpacing,
            verticalSpacing: Constants.metaSpacing
        ) {
            if content.isLive {
                liveBadge
            }

            if let categoryName = content.categoryName {
                categoryBadge(categoryName)
            }

            if let volumeText = content.volumeText {
                labelledValue(Localization.predictionEventTotalVolume, value: volumeText)
            }

            volumeChange(content.volumeChange)
        }
    }

    private func categoryBadge(_ name: String) -> some View {
        Badge(label: name, accessibilityLabel: nil)
            .size(.x4)
            .variant(.tinted)
            .appearance(.neutral)
    }

    private var liveBadge: some View {
        // [REDACTED_TODO_COMMENT]
        Badge(label: "Live", accessibilityLabel: nil)
            .size(.x4)
            .variant(.solid)
            .appearance(.success)
            .slotStart(DesignSystem.Icons.Dot.filled12)
    }

    private func volumeChange(_ change: PolymarketEventDetailsContent.VolumeChange) -> some View {
        HStack(spacing: Constants.metaValueSpacing) {
            Text(Localization.predictionDetails24hChange)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

            PriceChangeView(
                state: .loaded(changeType: change.type, text: change.text),
                showIconForNeutral: false,
                useRedesignColors: true
            )
        }
    }

    private func labelledValue(_ label: String, value: String) -> some View {
        HStack(spacing: Constants.metaValueSpacing) {
            Text(label)
                .foregroundStyle(DesignSystem.Color.textSecondary)

            Text(value)
                .foregroundStyle(DesignSystem.Color.textPrimary)
        }
        .font(token: DesignSystem.Font.captionMediumToken)
        .lineLimit(1)
    }

    // MARK: - Markets

    private func marketsSection(_ content: PolymarketEventDetailsContent) -> some View {
        VStack(spacing: Constants.marketCardSpacing) {
            ForEach(content.activeMarkets) { model in
                PolymarketMarketCard(model: model)
            }

            if content.showsClosedMarketsToggle {
                closedMarketsToggle(count: content.closedMarkets.count)
                    .padding(.top, Constants.closedMarketsTopPadding)
            }

            if !content.showsClosedMarketsToggle || viewModel.isClosedMarketsExpanded {
                ForEach(content.closedMarkets) { model in
                    PolymarketMarketCard(model: model)
                }
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.marketsVerticalPadding)
    }

    private func closedMarketsToggle(count: Int) -> some View {
        SwiftUI.Button {
            withAnimation { viewModel.handleViewAction(.toggleClosedMarkets) }
        } label: {
            Text("\(Localization.predictionDetailsClosedMarkets) (\(count))")
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, Constants.closedMarketsHorizontalPadding)
                .frame(minWidth: Constants.closedMarketsMinWidth, minHeight: Constants.closedMarketsHeight)
                .background(DesignSystem.Color.bgTransparentPrimary, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Summary

    @ViewBuilder
    private func summarySection(_ content: PolymarketEventDetailsContent) -> some View {
        if content.description != nil || content.hasInfoRows {
            VStack(spacing: Constants.summarySpacing) {
                if let description = content.description {
                    PolymarketExpandableDescription(
                        text: description,
                        isExpanded: viewModel.isDescriptionExpanded,
                        onReadMore: { viewModel.handleViewAction(.expandDescription) }
                    )
                    .padding(.horizontal, Constants.textHorizontalPadding)
                    .padding(.top, Constants.descriptionTopPadding)
                }

                if content.hasInfoRows {
                    infoRows(content)
                }
            }
            .padding(.vertical, Constants.summarySpacing)
        }
    }

    private func infoRows(_ content: PolymarketEventDetailsContent) -> some View {
        VStack(spacing: 0) {
            if let resolutionDateText = content.resolutionDateText {
                infoRow(
                    title: Localization.predictionDetailsResolutionDate,
                    value: resolutionDateText,
                    showsDivider: content.marketOpenedDateText != nil
                )
            }

            if let marketOpenedDateText = content.marketOpenedDateText {
                infoRow(
                    title: Localization.predictionDetailsMarketOpened,
                    value: marketOpenedDateText,
                    showsDivider: false
                )
            }
        }
        .padding(.horizontal, Constants.infoRowsHorizontalPadding)
    }

    private func infoRow(title: String, value: String, showsDivider: Bool) -> some View {
        Row(title: title, value: value)
            .overrideTextColors(.init(value: DesignSystem.Color.textSecondary))
            .showDivider(showsDivider)
    }

    // MARK: - Title transfer

    private var pageHandoffProgress: CGFloat {
        clamp(titleTransferProgress / Constants.pageHandoffShare, min: 0, max: 1)
    }

    private var barHandoffProgress: CGFloat {
        clamp((titleTransferProgress - (1 - Constants.barHandoffShare)) / Constants.barHandoffShare, min: 0, max: 1)
    }

    private var pageContentOpacity: CGFloat {
        1 - pageHandoffProgress
    }

    private var pageTitleScale: CGFloat {
        1 - (1 - Constants.barTitleFontRatio) * pageHandoffProgress
    }

    private var barTitleOpacity: CGFloat {
        barHandoffProgress
    }

    private var barTitleScale: CGFloat {
        Constants.barTitleMinScale + (1 - Constants.barTitleMinScale) * barHandoffProgress
    }

    private var titleTransferStart: CGFloat {
        let titleBottom = Constants.headerVerticalPadding + headerTitleHeight

        return max(0, titleBottom - Constants.titleTransferDistance)
    }

    private func updateTitleTransfer(contentOffset: CGPoint) {
        let travelled = contentOffset.y - titleTransferStart
        titleTransferProgress = clamp(travelled / Constants.titleTransferDistance, min: 0, max: 1)
    }
}

// MARK: - Failure copy

private extension PolymarketEventDetailsViewModel.Failure {
    var message: String {
        switch self {
        // [REDACTED_TODO_COMMENT]
        case .notFound: "This event is no longer available"
        case .generic: Localization.commonSomethingWentWrong
        }
    }
}

// MARK: - Constants

private extension PolymarketEventDetailsView {
    enum Constants {
        static let scrollSpace = "PolymarketEventDetailsScroll"

        static let horizontalPadding: CGFloat = 16
        static let textHorizontalPadding: CGFloat = 20

        static let toolbarHeight: CGFloat = 44
        static let barTopPadding: CGFloat = 8
        static let barBottomPadding: CGFloat = 16
        static let barSpacing: CGFloat = 12
        static let barButtonSide: CGFloat = 44
        static let collapsedTitleSpacing: CGFloat = 4
        static let barSubtitleSpacing: CGFloat = 4
        static let titleTransferDistance: CGFloat = 40
        static let pageHandoffShare: CGFloat = 0.55
        static let barHandoffShare: CGFloat = 0.55
        static let pageTitleTravelX: CGFloat = 100
        static let barTitleFontRatio: CGFloat = 16.0 / 28.0
        static let barTitleMinScale: CGFloat = 0.8
        static let handoffAnimation = Animation.easeOut(duration: 0.15)

        static let headerSpacing: CGFloat = 8
        static let headerVerticalPadding: CGFloat = 16
        static let metaSpacing: CGFloat = 8
        static let metaValueSpacing: CGFloat = 2

        static let marketCardSpacing: CGFloat = 8
        static let marketsVerticalPadding: CGFloat = 16
        static let closedMarketsTopPadding: CGFloat = 4
        static let closedMarketsHeight: CGFloat = 36
        static let closedMarketsMinWidth: CGFloat = 56
        static let closedMarketsHorizontalPadding: CGFloat = 14

        static let summarySpacing: CGFloat = 24
        static let descriptionTopPadding: CGFloat = 8
        static let infoRowsHorizontalPadding: CGFloat = 4
    }
}
