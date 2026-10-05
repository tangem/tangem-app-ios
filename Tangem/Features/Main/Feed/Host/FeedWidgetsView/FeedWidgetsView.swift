//
//  FeedWidgetsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemFoundation
import TangemUIUtils

struct FeedWidgetsView: View {
    @ObservedObject var viewModel: FeedWidgetsViewModel

    let viewport: CGRect
    let isContentVisible: Bool

    @Environment(\.scenePhase) private var scenePhase

    @ScaledMetric private var compactCardWidth: CGFloat = Constants.compactCardWidth
    @ScaledMetric private var compactCardHeight: CGFloat = Constants.compactCardHeight
    @ScaledMetric private var wideCardWidth: CGFloat = Constants.wideCardWidth

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: Constants.spacing) {
                    ForEach(viewModel.columns) { column in
                        view(
                            for: column,
                            productWidth: productCardWidth(in: geometry.size.width),
                            viewport: viewport.intersection(geometry.frame(in: .global))
                        )
                    }
                }
                .padding(.horizontal, Constants.horizontalInset)
                .id(FeedConstants.widgetsAnchorID)
            }
        }
        .frame(height: columnHeight)
        .onAppear { viewModel.updateContentVisibility(isTrackingVisibility) }
        .onChange(of: isTrackingVisibility) { viewModel.updateContentVisibility($0) }
        .onDisappear { viewModel.updateContentVisibility(false) }
    }

    @ViewBuilder
    private func view(for column: FeedWidgetColumn, productWidth: CGFloat, viewport: CGRect) -> some View {
        switch column {
        case .pair(let top, let bottom):
            VStack(spacing: Constants.spacing) {
                view(for: top, productWidth: productWidth, viewport: viewport)
                view(for: bottom, productWidth: productWidth, viewport: viewport)
            }
        case .single(let widget):
            view(for: widget, productWidth: productWidth, viewport: viewport)
        }
    }

    @ViewBuilder
    private func view(for widget: FeedWidget, productWidth: CGFloat, viewport: CGRect) -> some View {
        let card = content(for: widget)
            .frame(size: cardSize(for: widget.span, productWidth: productWidth))

        widgetButton(widget, card: card)
            .onGeometryChange(for: FeedWidget?.self, of: { geometry in
                viewport.intersection(geometry.frame(in: .global)).isEmpty ? nil : widget
            }) { visibleWidget in
                viewModel.updateVisibility(of: visibleWidget ?? widget, isVisible: visibleWidget != nil)
            }
            .onDisappear { viewModel.updateVisibility(of: widget, isVisible: false) }
    }

    @ViewBuilder
    private func widgetButton(_ widget: FeedWidget, card: some View) -> some View {
        if widget.loadingState.isLoading {
            card
        } else {
            Button {
                viewModel.select(widget)
            } label: {
                card.contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(accessibilityIdentifier(for: widget))
        }
    }

    private func accessibilityIdentifier(for widget: FeedWidget) -> String? {
        switch widget {
        case .addAccount:
            AccountsAccessibilityIdentifiers.feedAddAccountBanner
        case .forYou:
            MainAccessibilityIdentifiers.feedForYouWidget
        case .startEarning, .tangemPay, .referFriend, .polymarket, .collectibles:
            nil
        }
    }

    @ViewBuilder
    private func content(for widget: FeedWidget) -> some View {
        switch widget {
        case .forYou:
            FeedForYouWidgetView()

        case .addAccount:
            FeedAddAccountWidgetView()

        case .startEarning(let state):
            FeedEarnWidgetView(state: state)

        case .tangemPay:
            FeedTangemPayWidgetView()

        case .referFriend(let reward):
            FeedReferralWidgetView(reward: reward)

        case .polymarket:
            PolymarketWidgetView()

        case .collectibles:
            CollectiblesWidgetView()
        }
    }
}

// MARK: - Private

private extension FeedWidgetsView {
    var isTrackingVisibility: Bool {
        isContentVisible && scenePhase == .active
    }

    var columnHeight: CGFloat {
        compactCardHeight * 2 + Constants.spacing
    }

    func cardSize(for span: FeedWidget.Span, productWidth: CGFloat) -> CGSize {
        switch span {
        case .compact: CGSize(width: compactCardWidth, height: compactCardHeight)
        case .wide: CGSize(width: productWidth, height: columnHeight)
        }
    }

    func productCardWidth(in availableWidth: CGFloat) -> CGFloat {
        guard viewModel.stretchesProductCard else { return wideCardWidth }

        let compactColumnCount = CGFloat(viewModel.columns.count - 1)
        let remainingWidth = availableWidth - Constants.horizontalInset * 2
            - compactColumnCount * (compactCardWidth + Constants.spacing)

        return max(wideCardWidth, remainingWidth)
    }
}

// MARK: - Constants

private extension FeedWidgetsView {
    enum Constants {
        static let spacing: CGFloat = 8
        static let horizontalInset: CGFloat = 16
        static let compactCardWidth: CGFloat = 120
        static let compactCardHeight: CGFloat = 86
        static let wideCardWidth: CGFloat = 186
    }
}
