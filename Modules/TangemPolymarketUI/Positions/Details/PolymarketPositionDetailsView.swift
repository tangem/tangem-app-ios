//
//  PolymarketPositionDetailsView.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

public struct PolymarketPositionDetailsView: View {
    private let model: Model
    private let onClose: () -> Void

    public init(model: Model, onClose: @escaping () -> Void) {
        self.model = model
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            PolymarketTopBar(onClose: onClose)
                .padding(.top, Constants.topBarTopPadding)

            content
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: .zero) { footer }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: Constants.blockSpacing) {
                PolymarketPositionHeader(model: model.header)

                if let notice = model.notice {
                    PolymarketPositionNoticeView(notice: notice)
                }

                VStack(spacing: Constants.groupSpacing) {
                    PolymarketMarketCard(model: model.market)

                    PolymarketPositionStatsGrid(tiles: model.stats)
                }

                PolymarketDetailsRowsBlock(rows: model.rows)
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.bottom, Constants.contentBottomPadding)
        }
    }

    private var footer: some View {
        HStack(spacing: Constants.groupSpacing) {
            actionButton(model.secondaryAction, styleType: .secondary(.default))

            actionButton(model.primaryAction, styleType: .default)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.footerVerticalPadding)
        .background {
            Fade(position: .bottom)
                .blurred()
                .ignoresSafeArea(edges: .bottom)
        }
    }

    @ViewBuilder
    private func actionButton(_ action: Action?, styleType: TangemUI.Button.StyleType) -> some View {
        if let action {
            TangemUI.Button(label: action.title, accessibilityLabel: action.title, action: action.perform)
                .styleType(styleType)
                .size(.x12)
                .horizontalLayout(.infinity)
                .loading(.spinner(if: action.isLoading))
                .disabled(!action.isEnabled)
        }
    }
}

// MARK: - Model

public extension PolymarketPositionDetailsView {
    struct Model {
        public let header: PolymarketPositionHeader.Model
        public let market: PolymarketMarketCard.Model
        public let stats: [PolymarketPositionStatTile.Model]
        public let rows: [PolymarketDetailsRowsBlock.Row]
        public let notice: PolymarketPositionNotice?
        public let secondaryAction: Action?
        public let primaryAction: Action?

        public init(
            header: PolymarketPositionHeader.Model,
            market: PolymarketMarketCard.Model,
            stats: [PolymarketPositionStatTile.Model],
            rows: [PolymarketDetailsRowsBlock.Row],
            notice: PolymarketPositionNotice? = nil,
            secondaryAction: Action?,
            primaryAction: Action?
        ) {
            self.header = header
            self.market = market
            self.stats = stats
            self.rows = rows
            self.notice = notice
            self.secondaryAction = secondaryAction
            self.primaryAction = primaryAction
        }
    }

    struct Action {
        public let title: String
        public let isEnabled: Bool
        public let isLoading: Bool
        public let perform: () -> Void

        public init(title: String, isEnabled: Bool, isLoading: Bool = false, perform: @escaping () -> Void) {
            self.title = title
            self.isEnabled = isEnabled
            self.isLoading = isLoading
            self.perform = perform
        }
    }
}

// MARK: - Constants

private extension PolymarketPositionDetailsView {
    enum Constants {
        static let topBarTopPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 16
        static let blockSpacing: CGFloat = 12
        static let groupSpacing: CGFloat = 8
        static let footerVerticalPadding: CGFloat = 16
        static let contentBottomPadding: CGFloat = 24
    }
}
