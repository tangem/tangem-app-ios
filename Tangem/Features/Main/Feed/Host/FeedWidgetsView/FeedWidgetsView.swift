//
//  FeedWidgetsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct FeedWidgetsView: View {
    @ObservedObject var viewModel: FeedWidgetsViewModel

    @ScaledMetric private var compactCardWidth: CGFloat = Constants.compactCardWidth
    @ScaledMetric private var compactCardHeight: CGFloat = Constants.compactCardHeight
    @ScaledMetric private var wideCardWidth: CGFloat = Constants.wideCardWidth
    @ScaledMetric private var accessorySide: CGFloat = Constants.accessorySide
    @ScaledMetric private var iconSide: CGFloat = Constants.iconSide

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: Constants.spacing) {
                ForEach(viewModel.columns) { column in
                    view(for: column)
                }
            }
            .padding(.horizontal, Constants.horizontalInset)
            .id(FeedConstants.widgetsAnchorID)
        }
    }

    @ViewBuilder
    private func view(for column: FeedWidgetColumn) -> some View {
        switch column {
        case .pair(let top, let bottom):
            VStack(spacing: Constants.spacing) {
                view(for: top)
                view(for: bottom)
            }
        case .single(let widget):
            view(for: widget)
        }
    }

    @ViewBuilder
    private func view(for widget: FeedWidget) -> some View {
        switch widget {
        case .forYou:
            // [REDACTED_TODO_COMMENT]
            smallWidget(title: Localization.forYouTitle) {
                FeedPortfolioDonutView()
            }
            .glowRing(cornerRadius: Constants.cornerRadius)

        case .addAccount:
            // [REDACTED_TODO_COMMENT]
            smallWidget(title: Localization.accountFormCreateButton) {
                addAccountIcon
            }

        case .startEarning:
            // [REDACTED_TODO_COMMENT]
            largePlaceholder(title: "Start earning")

        case .tangemPay:
            // [REDACTED_TODO_COMMENT]
            largePlaceholder(title: Localization.tangempayTitle)
        }
    }
}

// MARK: - Subviews

private extension FeedWidgetsView {
    var compactCardSize: CGSize {
        CGSize(width: compactCardWidth, height: compactCardHeight)
    }

    var wideCardSize: CGSize {
        CGSize(width: wideCardWidth, height: compactCardHeight * 2 + Constants.spacing)
    }

    var addAccountIcon: some View {
        DesignSystem.Icons.SignPlus.regular16.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(size: CGSize(bothDimensions: iconSide))
            .foregroundStyle(DesignSystem.Color.iconStaticLight)
            .frame(size: CGSize(bothDimensions: accessorySide))
            .background(DesignSystem.Color.bgAccentBlue, in: Circle())
    }

    func smallWidget(title: String, @ViewBuilder accessory: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            accessory()
                .frame(size: CGSize(bothDimensions: accessorySide))

            Spacer(minLength: 0)

            Text(title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
        }
        .padding(Constants.padding)
        .frame(size: compactCardSize, alignment: .leading)
        .background(DesignSystem.Color.bgOpaquePrimary, in: RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    func largePlaceholder(title: String) -> some View {
        Text(title)
            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
            .padding(Constants.padding)
            .frame(size: wideCardSize)
            .background(DesignSystem.Color.bgOpaquePrimary, in: RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }
}

// MARK: - Constants

private extension FeedWidgetsView {
    enum Constants {
        static let spacing: CGFloat = 8
        static let horizontalInset: CGFloat = 16
        static let padding: CGFloat = 12
        static let cornerRadius: CGFloat = 24
        static let accessorySide: CGFloat = 24
        static let iconSide: CGFloat = 16
        static let compactCardWidth: CGFloat = 120
        static let compactCardHeight: CGFloat = 86
        static let wideCardWidth: CGFloat = 188
    }
}
