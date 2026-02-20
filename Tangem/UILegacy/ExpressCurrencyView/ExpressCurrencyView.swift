//
//  ExpressCurrencyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemLocalization

struct ExpressCurrencyView<Content: View>: View {
    @ObservedObject private var viewModel: ExpressCurrencyViewModel
    private let content: () -> Content

    private let imageSize = CGSize(width: 36, height: 36)
    // With 2 padding in the all edges
    private let tokenIconSize = CGSize(width: 40, height: 40)
    private let chevronIconSize = CGSize(width: 9, height: 9)
    private var didTapChangeCurrency: () -> Void = {}
    private var didTapNetworkFeeInfoButton: ((ExpressCurrencyViewModel.PriceChangeState) -> Void)?

    @State private var symbolSize: CGSize = .zero

    init(viewModel: ExpressCurrencyViewModel, content: @escaping () -> Content) {
        self.viewModel = viewModel
        self.content = content
    }

    var body: some View {
        VStack(spacing: 6) {
            topContent

            mainContent

            bottomContent
        }
    }

    var topContent: some View {
        HStack(spacing: 0) {
            headerView

            Spacer()

            LoadableBalanceView(
                state: viewModel.balanceState,
                style: .init(font: Fonts.Regular.footnote, textColor: Colors.Text.tertiary),
                loader: .init(
                    size: CGSize(width: 72, height: 12),
                    padding: .init(top: 2, leading: 0, bottom: 2, trailing: 0),
                    cornerRadius: 3
                )
            )
        }
    }

    @ViewBuilder
    var headerView: some View {
        switch (viewModel.headerType, viewModel.errorState) {
        case (_, .none):
            ExpressCurrencyDefaultHeaderView(headerType: viewModel.headerType)
        case (_, .some(let errorState)):
            ExpressCurrencyErrorHeaderView(errorState: errorState)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        HStack(alignment: .top, spacing: 0) {
            content()

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
            HStack(spacing: 4) {
                LoadableTextView(
                    state: viewModel.fiatAmountState,
                    font: Fonts.Regular.footnote,
                    textColor: Colors.Text.tertiary,
                    loaderSize: CGSize(width: 70, height: 12),
                    lineLimit: 1,
                    isSensitiveText: false
                )

                infoButton
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
    private var infoButton: some View {
        if let priceChangeState = viewModel.priceChangeState, let didTapNetworkFeeInfoButton {
            Button(action: { didTapNetworkFeeInfoButton(priceChangeState) }) {
                switch priceChangeState {
                case .info:
                    infoButtonIcon
                        .foregroundColor(Colors.Icon.informative)
                case .percent(let percent, _):
                    HStack(spacing: 2) {
                        Text(percent)
                            .style(Fonts.Regular.footnote, color: Colors.Text.attention)

                        infoButtonIcon
                            .foregroundColor(Colors.Icon.attention)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var infoButtonIcon: some View {
        Assets.infoIconMini.image
            .renderingMode(.template)
            .resizable()
            .frame(width: 16, height: 16)
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

extension ExpressCurrencyView: Setupable {
    func didTapChangeCurrency(_ block: @escaping () -> Void) -> Self {
        map { $0.didTapChangeCurrency = block }
    }

    func didTapNetworkFeeInfoButton(_ block: @escaping (ExpressCurrencyViewModel.PriceChangeState) -> Void) -> Self {
        map { $0.didTapNetworkFeeInfoButton = block }
    }
}
