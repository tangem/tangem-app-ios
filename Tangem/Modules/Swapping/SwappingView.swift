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
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            GroupedScrollView {
                swappingViews

                MainButton(text: "Swap", icon: .trailing(Assets.tangemIcon)) {}
            }
        }
    }

    @ViewBuilder
    private var swappingViews: some View {
        ZStack(alignment: .center) {
            VStack(spacing: 14) {
                SendCurrencyView(
                    viewModel: viewModel.sendCurrencyViewModel,
                    decimalValue: $viewModel.sendDecimalValue
                )

                ReceiveCurrencyView(viewModel: viewModel.receiveCurrencyViewModel)
            }

            swappingButton
        }
    }

    @ViewBuilder
    private var swappingButton: some View {
        Group {
            if viewModel.isLoading {
                ActivityIndicatorView(color: .gray)
            } else {
                Button(action: viewModel.swapButtonDidTap) {
                    Assets.swappingIcon
                        .resizable()
                        .frame(width: 20, height: 20)
                }
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
}

struct SwappingView_Preview: PreviewProvider {
    static let viewModel = SwappingViewModel(coordinator: SwappingCoordinator())

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            SwappingView(viewModel: viewModel)
                .padding()
        }
    }
}
