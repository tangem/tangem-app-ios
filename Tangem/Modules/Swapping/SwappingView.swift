//
//  SwappingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SwappingView: View {
    @ObservedObject private var viewModel: SwappingViewModel

    init(viewModel: SwappingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .center) {
            VStack(spacing: 14) {
                SendCurrencyView(
                    viewModel: viewModel.sendCurrencyViewModel,
                    textFieldText: $viewModel.sendCurrencyValueText
                )

                ReceiveCurrencyView(viewModel: viewModel.receiveCurrencyViewModel)
            }

            swapContent
        }
    }

    @ViewBuilder
    private var swapContent: some View {
        Group {
            if viewModel.isLoading {
                ActivityIndicatorView(color: .gray)
            } else {
                swapButton
            }
        }
        .frame(width: 44, height: 44)
        .background(Colors.Background.primary)
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Colors.Stroke.primary, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var swapButton: some View {
        Button(action: viewModel.swapButtonDidTap) {
            Assets.swappingIcon
                .resizable()
                .frame(width: 20, height: 20)
        }
    }
}

struct SwappingView_Preview: PreviewProvider {
    static let viewModel = SwappingViewModel(
        coordinator: SwappingCoordinator(),
        sendCurrencyViewModel: SendCurrencyViewModel(
            balance: 3043.75,
            fiatValue: 0,
            tokenIcon: .init(tokenItem: .blockchain(.bitcoin(testnet: false)))
        ),
        receiveCurrencyViewModel: ReceiveCurrencyViewModel(
            state: .loaded(0, fiatValue: 0),
            tokenIcon: .init(tokenItem: .blockchain(.polygon(testnet: false))),
            didTapTokenView: {}
        )
    )

    static var previews: some View {
        SwappingView(viewModel: viewModel)
    }
}
