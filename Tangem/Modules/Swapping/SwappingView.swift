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
            .scrollDismissesKeyboardCompat(true)
        }
        .navigationBarTitle(Text("swapping_swap".localized), displayMode: .inline)
    }

    @ViewBuilder
    private var swappingViews: some View {
        ZStack(alignment: .center) {
            VStack(spacing: 14) {
                if let sendCurrencyViewModel = viewModel.sendCurrencyViewModel {
                    SendCurrencyView(
                        viewModel: sendCurrencyViewModel,
                        decimalValue: $viewModel.sendDecimalValue
                    )
                }

                if let receiveCurrencyViewModel = viewModel.receiveCurrencyViewModel {
                    ReceiveCurrencyView(viewModel: receiveCurrencyViewModel)
                        .didTapTokenView {
                            viewModel.userDidTapChangeDestinationButton()
                        }
                }
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
                Button(action: viewModel.userDidTapSwapExchangeItemsButton) {
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
                SwappingFeeRowView(viewModel: viewModel)
            case let .warning(viewModel):
                DefaultWarningRow(viewModel: viewModel)
            }
        }
        .verticalPadding(0)
    }

    @ViewBuilder
    private var mainButton: some View {
        MainButton(
            text: viewModel.mainButtonTitle.title,
            icon: viewModel.mainButtonTitle.icon,
            isDisabled: !viewModel.mainButtonIsEnabled,
            action: viewModel.userDidTapMainButton
        )
    }
}

struct SwappingView_Preview: PreviewProvider {
    static let viewModel = SwappingViewModel(
        exchangeManager: ExchangeManagerMock(),
        swappingDestinationService: SwappingDestinationServiceMock(),
        userWalletsListProvider: UserWalletsListProviderMock(),
        tokenIconURLBuilding: TokenIconURLBuilderMock(),
        coordinator: SwappingCoordinator()
    )

    static var previews: some View {
        NavigationView {
            SwappingView(viewModel: viewModel)
        }
    }
}
