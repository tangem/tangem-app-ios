//
//  ExpressView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressView: View {
    @ObservedObject private var viewModel: ExpressViewModel

    init(viewModel: ExpressViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            GroupedScrollView(spacing: 14) {
                swappingViews

                providerSection

                feeSection

                informationSection
            }
            .scrollDismissesKeyboardCompat(true)
            // For animate button below informationSection
            .animation(.easeInOut, value: viewModel.providerState?.id)
            .animation(.easeInOut, value: viewModel.expressFeeRowViewModel == nil)

            mainButton
        }
        .navigationBarTitle(Text(Localization.commonSwap), displayMode: .inline)
        .alert(item: $viewModel.errorAlert, content: { $0.alert })
        .animation(.default, value: viewModel.notificationInputs)
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
                    .didTapMaxAmount(viewModel.userDidTapMaxAmount)
                    .didTapChangeCurrency {
                        viewModel.userDidTapChangeSourceButton()
                    }
                }

                if let receiveCurrencyViewModel = viewModel.receiveCurrencyViewModel {
                    ReceiveCurrencyView(viewModel: receiveCurrencyViewModel)
                        .didTapChangeCurrency {
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
        Button(action: viewModel.userDidTapSwapSwappingItemsButton) {
            if viewModel.isSwapButtonLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.informative))
            } else {
                Assets.swappingIcon.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(viewModel.isSwapButtonDisabled ? Colors.Icon.inactive : Colors.Icon.primary1)
            }
        }
        .disabled(viewModel.isSwapButtonLoading || viewModel.isSwapButtonDisabled)
        .frame(width: 44, height: 44)
        .background(Colors.Background.primary)
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Colors.Stroke.primary, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var informationSection: some View {
        ForEach(viewModel.notificationInputs) {
            NotificationView(input: $0)
                .setButtonsLoadingState(to: viewModel.isSwapButtonLoading)
                .transition(.notificationTransition)
        }
    }

    @ViewBuilder
    private var feeSection: some View {
        GroupedSection(viewModel.expressFeeRowViewModel) {
            ExpressFeeRowView(viewModel: $0)
        }
        .interSectionPadding(12)
        .verticalPadding(0)
    }

    @ViewBuilder
    private var providerSection: some View {
        GroupedSection(viewModel.providerState) { state in
            switch state {
            case .loading:
                LoadingProvidersRow()
            case .loaded(let data):
                ProviderRowView(viewModel: data)
            }
        }
        .interSectionPadding(12)
        .verticalPadding(0)
    }

    @ViewBuilder
    private var mainButton: some View {
        VStack(alignment: .center, spacing: 12) {
            Spacer()

            legalView
                .padding(.horizontal, 18)

            MainButton(
                title: viewModel.mainButtonState.title,
                icon: viewModel.mainButtonState.icon,
                isLoading: viewModel.mainButtonIsLoading,
                isDisabled: !viewModel.mainButtonIsEnabled,
                action: viewModel.didTapMainButton
            )
        }
        .padding(.horizontal, 14)
        .padding(.bottom, UIApplication.safeAreaInsets.bottom + 10)
        .edgesIgnoringSafeArea(.bottom)
        .ignoresSafeArea(.keyboard)
    }

    @ViewBuilder
    private var legalView: some View {
        if let legalText = viewModel.legalText {
            if #available(iOS 15, *) {
                Text(AttributedString(legalText))
                    .font(Fonts.Regular.footnote)
                    .multilineTextAlignment(.center)
            } else {
                GeometryReader { proxy in
                    VStack(spacing: .zero) {
                        Spacer()
                            .layoutPriority(1)

                        // AttributedTextView(UILabel) doesn't tappable on iOS 14
                        AttributedTextView(legalText, textAlignment: .center, maxLayoutWidth: proxy.size.width)
                    }
                }
            }
        }
    }
}

/*
 struct ExpressView_Preview: PreviewProvider {
     static let viewModel = ExpressViewModel(
         initialWallet: .mock,
         swappingInteractor: .init(
             swappingManager: SwappingManagerMock(),
             userTokensManager: UserTokensManagerMock(),
             currencyMapper: CurrencyMapper(),
             blockchainNetwork: PreviewCard.ethereum.blockchainNetwork!
         ),
         swappingDestinationService: SwappingDestinationServiceMock(),
         tokenIconURLBuilder: TokenIconURLBuilder(),
         transactionSender: TransactionSenderMock(),
         fiatRatesProvider: FiatRatesProviderMock(),
         swappingFeeFormatter: SwappingFeeFormatterMock(),
         coordinator: ExpressCoordinator()
     )

     static var previews: some View {
         NavigationView {
             ExpressView(viewModel: viewModel)
         }
     }
 }
 */
