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

            GroupedScrollView(spacing: 14) {
                swappingViews

                refreshWarningSection

                informationSection

                mainButton
            }
            .keyboardAdaptive()
            .scrollDismissesKeyboardCompat()
        }
        .navigationBarTitle(Text("Swap"), displayMode: .inline)
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
        .padding(.top, 16)
    }

    @ViewBuilder
    private var swappingButton: some View {
        Group {
            if viewModel.isLoading {
                ProgressViewCompat(color: Colors.Icon.informative)
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

    @ViewBuilder
    private var refreshWarningSection: some View {
        GroupedSection(viewModel.refreshWarningRowViewModel) {
            DefaultWarningRow(viewModel: $0)
        }
        .verticalPadding(0)
    }

    @ViewBuilder
    private var informationSection: some View {
        GroupedSection(viewModel.informationSectionViewModels) { item in
            switch item {
            case let .fee(viewModel):
                DefaultRowView(viewModel: viewModel)
            case let .warning(viewModel):
                DefaultWarningRow(viewModel: viewModel)
            }
        }
        .verticalPadding(0)
    }

    @ViewBuilder
    private var mainButton: some View {
        MainButton(
            text: "Swap",
            icon: .trailing(Assets.tangemIcon),
            isDisabled: !viewModel.mainButtonIsEnabled
        ) {}
    }
}

struct SwappingView_Preview: PreviewProvider {
    static let viewModel = SwappingViewModel(coordinator: SwappingCoordinator())

    static var previews: some View {
        NavigationView {
            SwappingView(viewModel: viewModel)
        }
    }
}
