//
//  ReceiveCurrencyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ReceiveCurrencyView: View {
    @ObservedObject private var viewModel: ReceiveCurrencyViewModel

    private let imageSize = CGSize(width: 36, height: 36)
    // With 2 padding in the all edges
    private let tokenIconSize = CGSize(width: 40, height: 40)
    private let chevronIconSize = CGSize(width: 9, height: 9)
    private var didTapChangeCurrency: () -> Void = {}

    @State private var symbolSize: CGSize = .zero

    init(viewModel: ReceiveCurrencyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 6) {
            ExpressCurrencyTopView(title: Localization.swappingToTitle, state: viewModel.topViewState)
                .border(Color.purple)

            mainContent
                .border(Color.red)

            bottomContent
                .border(Color.orange)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        HStack(alignment: .top, spacing: 0) {
            LoadableTextView(
                state: viewModel.cryptoAmountState,
                font: Fonts.Regular.title1,
                textColor: Colors.Text.primary1,
                loaderSize: CGSize(width: 102, height: 24)
            )

            Spacer()

            Button(action: { didTapChangeCurrency() }) {
                ZStack(alignment: .trailing) {
                    iconContent
                        .padding(.all, 2)
                        // Chevron's space
                        .padding(.trailing, 12)

                    Assets.chevronDownMini.image
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.informative)
                        .frame(size: chevronIconSize)
                        // View have to keep size of the view same for both cases
                        .opacity(viewModel.canChangeCurrency ? 1 : 0)
                }
            }
            .disabled(!viewModel.canChangeCurrency)
        }
    }

    @ViewBuilder
    private var bottomContent: some View {
        HStack(spacing: 0) {
            HStack(spacing: 2) {
                LoadableTextView(
                    state: viewModel.fiatAmountState,
                    font: Fonts.Regular.footnote,
                    textColor: Colors.Text.tertiary,
                    loaderSize: CGSize(width: 70, height: 12),
                    lineLimit: 1,
                    isSensitiveText: false
                )

                if let priceChangePercent = viewModel.priceChangePercent {
                    HStack(spacing: 4) {
                        Text(priceChangePercent)
                            .style(Fonts.Regular.footnote, color: Colors.Text.attention)

                        Assets.attention.image
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                }
            }

            Spacer()

            LoadableTextView(
                state: viewModel.symbolState,
                font: Fonts.Bold.footnote,
                textColor: Colors.Text.primary1,
                loaderSize: CGSize(width: 30, height: 14),
                lineLimit: 1,
                isSensitiveText: false
            )
            .readGeometry(\.frame.size, bindTo: $symbolSize)
            // Chevron's space
            .padding(.trailing, 12)
            .offset(x: -tokenIconSize.width / 2 + symbolSize.width / 2)
        }
    }

    @ViewBuilder
    private var iconContent: some View {
        switch viewModel.tokenIconState {
        case .loading:
            SkeletonView()
                .frame(size: imageSize)
                .cornerRadius(imageSize.height / 2)
        case .notAvailable:
            Assets.emptyTokenList.image
                .renderingMode(.template)
                .resizable()
                .foregroundColor(Colors.Icon.inactive)
                .frame(size: imageSize)
        case .icon(let tokenIconInfo):
            TokenIcon(tokenIconInfo: tokenIconInfo, size: imageSize)
        }
    }
}

// MARK: - Setupable

extension ReceiveCurrencyView: Setupable {
    func didTapChangeCurrency(_ block: @escaping () -> Void) -> Self {
        map { $0.didTapChangeCurrency = block }
    }
}

struct ReceiveCurrencyView_Preview: PreviewProvider {
    static let viewModels = [
        ReceiveCurrencyViewModel(
            topViewState: .loading,
            cryptoAmountState: .loading,
            fiatAmountState: .loading,
            tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.ethereum(testnet: false)), isCustom: false)),
            symbolState: .loaded(text: "ETH"),
            canChangeCurrency: false
        ),
        ReceiveCurrencyViewModel(
            topViewState: .formatted("0.0058"),
            cryptoAmountState: .loading,
            fiatAmountState: .loading,
            tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.cardano(extended: false)), isCustom: false)),
            symbolState: .loaded(text: "ADA"),
            canChangeCurrency: false
        ),
        ReceiveCurrencyViewModel(
            topViewState: .formatted("0.0058"),
            cryptoAmountState: .loaded(text: "1100.46"),
            fiatAmountState: .loading,
            tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.polygon(testnet: false)), isCustom: false)),
            symbolState: .loaded(text: "MATIC"),
            canChangeCurrency: true
        ),
        ReceiveCurrencyViewModel(
            topViewState: .formatted("0.0058"),
            cryptoAmountState: .loading,
            fiatAmountState: .loaded(text: "1100.46"),
            tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.polygon(testnet: false)), isCustom: false)),
            symbolState: .loaded(text: "MATIC"),
            canChangeCurrency: true
        ),
        ReceiveCurrencyViewModel(
            topViewState: .formatted("0.0058"),
            cryptoAmountState: .loaded(text: "1100.46"),
            fiatAmountState: .loaded(text: "2100.46 $"),
            tokenIconState: .icon(TokenIconInfoBuilder().build(from: .token(.tetherMock, .polygon(testnet: false)), isCustom: false)),
            symbolState: .loaded(text: "USDT"),
            canChangeCurrency: true
        ),
        ReceiveCurrencyViewModel(
            topViewState: .formatted("0.0058"),
            cryptoAmountState: .loaded(text: "1100.46"),
            fiatAmountState: .loaded(text: "2100.46 $"),
            priceChangePercent: "-24.3 %",
            tokenIconState: .icon(TokenIconInfoBuilder().build(from: .token(.tetherMock, .polygon(testnet: false)), isCustom: false)),
            symbolState: .loaded(text: "USDT"),
            canChangeCurrency: true
        ),
    ]

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            VStack {
                ForEach(viewModels) {
                    GroupedSection($0) {
                        ReceiveCurrencyView(viewModel: $0)
                    }
                    .interSectionPadding(12)
                    .interItemSpacing(10)
                    .verticalPadding(0)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
