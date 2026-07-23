//
//  ManageTokensListItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils

struct ManageTokensListItemView: View {
    @ObservedObject private var viewModel: ManageTokensListItemViewModel

    private let isReadOnly: Bool

    @Environment(\.isAddAndOrganizeRedesignEnabled) private var isRedesign

    init(viewModel: ManageTokensListItemViewModel, isReadOnly: Bool) {
        self.viewModel = viewModel
        self.isReadOnly = isReadOnly
    }

    private let subtitle: String = Localization.currencySubtitleExpanded
    private let iconWidth: Double = 36

    private var symbolFormatted: String { "  \(viewModel.symbol)" }

    // MARK: - Redesign-aware styling

    private var nameFont: TangemFontStyle {
        isRedesign ? Font.Tangem.Body15.semibold : TangemFontStyle(font: Fonts.Bold.subheadline)
    }

    private var nameColor: Color {
        isRedesign ? .Tangem.Text.Neutral.primary : Colors.Text.primary1
    }

    private var symbolFont: TangemFontStyle {
        isRedesign ? Font.Tangem.Caption12.regular : TangemFontStyle(font: Fonts.Regular.caption1)
    }

    private var symbolColor: Color {
        isRedesign ? .Tangem.Text.Neutral.tertiary : Colors.Text.tertiary
    }

    private var subtitleFont: TangemFontStyle {
        isRedesign ? Font.Tangem.Caption13.regular : TangemFontStyle(font: Fonts.Regular.footnote)
    }

    private var subtitleColor: Color {
        isRedesign ? .Tangem.Text.Neutral.secondary : Colors.Text.secondary
    }

    private var chevronColor: Color {
        isRedesign ? .Tangem.Graphic.Neutral.tertiary : Colors.Icon.informative
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                IconView(url: viewModel.imageURL, size: CGSize(width: iconWidth, height: iconWidth), forceKingfisher: true)
                    .padding(.trailing, 12)
                    .saturation((isReadOnly || viewModel.atLeastOneTokenSelected) ? 1.0 : 0.0)

                VStack(alignment: .leading, spacing: 2) {
                    Group {
                        Text(viewModel.name)
                            .font(nameFont.font)
                            .tracking(nameFont.tracking)
                            .foregroundColor(nameColor)

                            + Text(symbolFormatted)
                            .font(symbolFont.font)
                            .tracking(symbolFont.tracking)
                            .foregroundColor(symbolColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                    HStack {
                        if viewModel.isExpanded {
                            Text(subtitle)
                                .style(subtitleFont, color: subtitleColor)

                            Spacer()
                        }
                    }
                }

                Spacer(minLength: 0)

                chevronView
            }
            .padding(.vertical, 16)
            .zIndex(20)
            .contentShape(Rectangle())
            .accessibilityIdentifier(ManageTokensAccessibilityIdentifiers.coinRow(viewModel.coinId))
            .onTapGesture {
                withAnimation {
                    viewModel.isExpanded.toggle()
                }
            }

            if viewModel.isExpanded {
                VStack(spacing: 0) {
                    ForEach(viewModel.items) {
                        ManageTokensItemNetworkSelectorView(viewModel: $0, arrowWidth: iconWidth)
                    }
                }
                .transition(.offset(.init(width: 0, height: -25)).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .padding(.horizontal, 16)
    }

    private var chevronView: some View {
        Assets.chevronDown24.image
            .foregroundStyle(chevronColor)
            .rotationEffect(viewModel.isExpanded ? Angle(degrees: 180) : .zero)
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var isTetherSelected = false
    @Previewable @State var isBabananasSelected = false
    @Previewable @State var isBusSelected = false
    @Previewable @State var isLongNameSelected = false
    @Previewable @State var isEthereumSelected = false

    func itemsList(count: Int, isSelected: Binding<Bool>) -> [ManageTokensItemNetworkSelectorViewModel] {
        var viewModels = [ManageTokensItemNetworkSelectorViewModel]()
        for i in 0 ..< count {
            viewModels.append(ManageTokensItemNetworkSelectorViewModel(
                tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
                isReadonly: false,
                isSelected: isSelected,
                position: i == (count - 1) ? .last : i == 0 ? .first : .middle
            ))
        }
        return viewModels
    }

    return ScrollView {
        let iconBuilder = IconURLBuilder()
        VStack(spacing: 0) {
            ManageTokensListItemView(viewModel: ManageTokensListItemViewModel(
                coinId: "tether",
                imageURL: iconBuilder.tokenIconURL(id: "tether"),
                name: "Tether",
                symbol: "USDT",
                items: itemsList(count: 11, isSelected: $isTetherSelected)
            ), isReadOnly: false)

            ManageTokensListItemView(viewModel: ManageTokensListItemViewModel(
                coinId: "binancecoin",
                imageURL: iconBuilder.tokenIconURL(id: "binancecoin"),
                name: "Babananas United",
                symbol: "BABASDT",
                items: itemsList(count: 15, isSelected: $isBabananasSelected)
            ), isReadOnly: true)

            ManageTokensListItemView(viewModel: ManageTokensListItemViewModel(
                coinId: "binancecoin",
                imageURL: iconBuilder.tokenIconURL(id: "binancecoin"),
                name: "Binance USD",
                symbol: "BUS",
                items: itemsList(count: 5, isSelected: $isBusSelected)
            ), isReadOnly: false)

            ManageTokensListItemView(viewModel: ManageTokensListItemViewModel(
                coinId: "avalanche-2",
                imageURL: iconBuilder.tokenIconURL(id: "avalanche-2"),
                name: "USDVVVSALN very-very-very-stupid-and-long-name",
                symbol: "BUS",
                items: itemsList(count: 3, isSelected: $isLongNameSelected)
            ), isReadOnly: true)

            ManageTokensListItemView(viewModel: ManageTokensListItemViewModel(
                coinId: "ethereum",
                imageURL: iconBuilder.tokenIconURL(id: "ethereum"),
                name: "Ethereum",
                symbol: "ETH",
                items: itemsList(count: 1, isSelected: $isEthereumSelected)
            ), isReadOnly: false)

            Spacer()
        }
    }
}
