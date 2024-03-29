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

    @State private var viewGeometryInfo: GeometryInfo = .zero
    @State private var contentSize: CGSize = .zero
    @State private var bottomViewSize: CGSize = .zero
    @State private var providerViewHeight: CGFloat = .zero
    @State private var loadingProviderViewHeight: CGFloat = .zero

    private var spacer: CGFloat {
        var height = viewGeometryInfo.frame.height
        height += viewGeometryInfo.safeAreaInsets.bottom
        height -= viewGeometryInfo.safeAreaInsets.top
        height -= contentSize.height
        height -= bottomViewSize.height
        return max(0, height)
    }

    init(viewModel: ExpressViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Colors.Background.tertiary.ignoresSafeArea(.all)

            GroupedScrollView(spacing: .zero) {
                VStack(spacing: 14) {
                    swappingViews

                    providerSection

                    feeSection

                    informationSection
                }
                .readGeometry(\.frame.size, bindTo: $contentSize)

                bottomView
            }
            .scrollDismissesKeyboardCompat(true)
        }
        .readGeometry(bindTo: $viewGeometryInfo)
        .ignoresSafeArea(.keyboard)
        .navigationBarTitle(Text(Localization.commonSwap), displayMode: .inline)
        .alert(item: $viewModel.alert) { $0.alert }
        // For animate button below informationSection
        .animation(.easeInOut, value: viewModel.providerState?.id)
        .animation(.default, value: viewModel.notificationInputs)
        .animation(.easeInOut, value: viewModel.expressFeeRowViewModel)
    }

    @ViewBuilder
    private var swappingViews: some View {
        ZStack(alignment: .center) {
            VStack(spacing: 14) {
                GroupedSection(viewModel.sendCurrencyViewModel) {
                    SendCurrencyView(viewModel: $0)
                        .maxAmountAction(viewModel.isMaxAmountButtonHidden ? nil : viewModel.userDidTapMaxAmount)
                        .didTapChangeCurrency(viewModel.userDidTapChangeSourceButton)
                }
                .innerContentPadding(12)

                GroupedSection(viewModel.receiveCurrencyViewModel) {
                    ReceiveCurrencyView(viewModel: $0)
                        .didTapChangeCurrency(viewModel.userDidTapChangeDestinationButton)
                        .didTapNetworkFeeInfoButton(viewModel.userDidTapPriceChangeInfoButton)
                }
                .innerContentPadding(12)
            }

            swappingButton
        }
        .padding(.top, 8)
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
        // To force notifications' appearing only after feeSection is appeared
        if viewModel.expressFeeRowViewModel != nil {
            ForEach(viewModel.notificationInputs) {
                NotificationView(input: $0)
                    .setButtonsLoadingState(to: viewModel.isSwapButtonLoading)
                    .transition(.notificationTransition)
            }
        }
    }

    @ViewBuilder
    private var feeSection: some View {
        GroupedSection(viewModel.expressFeeRowViewModel) {
            ExpressFeeRowView(viewModel: $0)
        }
        .innerContentPadding(12)
    }

    @ViewBuilder
    private var providerSection: some View {
        GroupedSection(viewModel.providerState) { state in
            switch state {
            case .loading:
                LoadingProvidersRow()
                    .readGeometry(\.frame.height, bindTo: $loadingProviderViewHeight)
                    .frame(height: max(providerViewHeight, loadingProviderViewHeight))
            case .loaded(let data):
                ProviderRowView(viewModel: data)
                    .readGeometry(\.frame.height, bindTo: $providerViewHeight)
                    .frame(height: max(providerViewHeight, loadingProviderViewHeight))
            }
        }
        .innerContentPadding(12)
    }

    @ViewBuilder
    private var bottomView: some View {
        VStack(spacing: 12) {
            FixedSpacer(height: spacer)

            VStack(spacing: 12) {
                legalView

                MainButton(
                    title: viewModel.mainButtonState.title,
                    icon: viewModel.mainButtonState.icon,
                    isLoading: viewModel.mainButtonIsLoading,
                    isDisabled: !viewModel.mainButtonIsEnabled,
                    action: viewModel.didTapMainButton
                )
            }
            .readGeometry(\.frame.size, bindTo: $bottomViewSize)
        }
        // To force `.animation(nil)` behaviour
        .animation(nil, value: UUID())
    }

    @ViewBuilder
    private var legalView: some View {
        if let legalText = viewModel.legalText {
            Text(legalText)
                .multilineTextAlignment(.center)
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
         feeFormatter: FeeFormatterMock(),
         coordinator: ExpressCoordinator()
     )

     static var previews: some View {
         NavigationView {
             ExpressView(viewModel: viewModel)
         }
     }
 }
 */
