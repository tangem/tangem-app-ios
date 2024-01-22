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
    private var didTapChangeCurrency: () -> Void = {}
    private var didTapPriceChangePercent: () -> Void = {}

    init(viewModel: ReceiveCurrencyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ExpressCurrencyView(viewModel: viewModel.expressCurrencyViewModel) {
            LoadableTextView(
                state: viewModel.cryptoAmountState,
                font: Fonts.Regular.title1,
                textColor: Colors.Text.primary1,
                loaderSize: CGSize(width: 102, height: 24)
            )
        }
        .didTapChangeCurrency(didTapChangeCurrency)
        .didTapPriceChangePercent(didTapPriceChangePercent)
    }
}

// MARK: - Setupable

extension ReceiveCurrencyView: Setupable {
    func didTapChangeCurrency(_ block: @escaping () -> Void) -> Self {
        map { $0.didTapChangeCurrency = block }
    }

    func didTapPriceChangePercent(_ block: @escaping () -> Void) -> Self {
        map { $0.didTapPriceChangePercent = block }
    }
}

struct ReceiveCurrencyView_Preview: PreviewProvider {
    static let viewModels = [
        ReceiveCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingToTitle),
                balanceState: .loading,
                fiatAmountState: .loading,
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.ethereum(testnet: false)), isCustom: false)),
                symbolState: .loaded(text: "ETH"),
                canChangeCurrency: false
            ),
            cryptoAmountState: .loading
        ),
        ReceiveCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingToTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loading,
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.cardano(extended: false)), isCustom: false)),
                symbolState: .loaded(text: "ADA"),
                canChangeCurrency: false
            ),
            cryptoAmountState: .loading
        ),
        ReceiveCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingToTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loading,
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.polygon(testnet: false)), isCustom: false)),
                symbolState: .loaded(text: "MATIC"),
                canChangeCurrency: true
            ),
            cryptoAmountState: .loaded(text: "1100.46")
        ),
        ReceiveCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingToTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loaded(text: "1100.46"),
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.polygon(testnet: false)), isCustom: false)),
                symbolState: .loaded(text: "MATIC"),
                canChangeCurrency: true
            ),
            cryptoAmountState: .loading
        ),
        ReceiveCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingToTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loaded(text: "2100.46 $"),
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .token(.tetherMock, .polygon(testnet: false)), isCustom: false)),
                symbolState: .loaded(text: "USDT"),
                canChangeCurrency: true
            ),
            cryptoAmountState: .loaded(text: "1100.46")
        ),
        ReceiveCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingToTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loaded(text: "2100.46 $"),
                priceChangePercent: "-24.3 %",
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .token(.tetherMock, .polygon(testnet: false)), isCustom: false)),
                symbolState: .loaded(text: "USDT"),
                canChangeCurrency: true
            ),
            cryptoAmountState: .loaded(text: "1100.46")
        ),
    ]

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            VStack {
                ForEach(viewModels) { viewModel in
                    GroupedSection(viewModel) { viewModel in
                        ReceiveCurrencyView(viewModel: viewModel)
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
