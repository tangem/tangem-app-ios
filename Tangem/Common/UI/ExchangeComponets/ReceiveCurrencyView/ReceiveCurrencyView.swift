//
//  ReceiveCurrencyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ReceiveCurrencyView: View {
    private let viewModel: ReceiveCurrencyViewModel
    private let tokenIconSize = CGSize(width: 36, height: 36)
    private var didTapTokenView: () -> Void = {}

    init(viewModel: ReceiveCurrencyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerLabel

            mainContent
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Colors.Background.primary)
        .cornerRadius(14)
    }

    private var headerLabel: some View {
        Text("exchange_receive_view_header".localized)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
    }

    @ViewBuilder
    private var mainContent: some View {
        HStack(spacing: 0) {
            switch viewModel.state {
            case .loading:
                loadingContent
            case .loaded:
                currencyContent
            }

            Spacer()

            SwappingTokenIconView(viewModel: viewModel.tokenIcon)
                .onTap(didTapTokenView)
        }
    }

    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            SkeletonView()
                .frame(width: 102, height: 21)
                .cornerRadius(6)

            SkeletonView()
                .frame(width: 40, height: 11)
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }

    private var currencyContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.value)
                .style(Fonts.Regular.title1, color: Colors.Text.primary1)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(viewModel.fiatValue)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }
}

// MARK: - Setupable

extension ReceiveCurrencyView: Setupable {
    func didTapTokenView(_ block: @escaping () -> Void) -> Self {
        map { $0.didTapTokenView = block }
    }
}

struct ReceiveCurrencyView_Preview: PreviewProvider {
    static let viewModel = ReceiveCurrencyViewModel(
        state: .loaded(1100.46, fiatValue: 1000.71),
        tokenIcon: SwappingTokenIconViewModel(
            state: .loaded(
                imageURL: TokenIconURLBuilderMock().iconURL(id: "polygon", size: .large),
                symbol: "MATIC"
            )
        )
    )

    static let loadingViewModel = ReceiveCurrencyViewModel(
        state: .loading,
        tokenIcon: SwappingTokenIconViewModel(
            state: .loaded(
                imageURL: TokenIconURLBuilderMock().iconURL(id: "polygon", size: .large),
                symbol: "MATIC"
            )
        )
    )

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            VStack {
                ReceiveCurrencyView(viewModel: viewModel)

                ReceiveCurrencyView(viewModel: loadingViewModel)
            }
            .padding(.horizontal, 16)
        }
    }
}
