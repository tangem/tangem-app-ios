//
//  SendAmountView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendAmountView: View {
    @ObservedObject var viewModel: SendAmountViewModel
    let namespace: Namespace

    private var amountMinTextScale: CGFloat?

    var body: some View {
        GroupedScrollView(spacing: 14) {
            amountContainer

            if !viewModel.animatingAuxiliaryViewsOnAppear {
                segmentControl
                    .transition(.offset(y: 100).combined(with: .opacity))
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onAppear(perform: viewModel.onAuxiliaryViewAppear)
        .onDisappear(perform: viewModel.onAuxiliaryViewDisappear)
    }

    private var amountContainer: some View {
        VStack(spacing: 32) {
            if !viewModel.animatingAuxiliaryViewsOnAppear {
                walletInfoView
                    // Because the top padding have to be is 16 to the white background
                    // But the bottom padding have to be is 12
                    .padding(.top, 4)
                    .transition(.offset(y: -100).combined(with: .opacity))
            }

            amountContent
        }
        .defaultRoundedBackground(
            with: Colors.Background.action,
            geometryEffect: .init(
                id: namespace.names.amountContainer,
                namespace: namespace.id
            )
        )
    }

    private var walletInfoView: some View {
        VStack(spacing: 4) {
            Text(viewModel.userWalletName)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .matchedGeometryEffect(id: namespace.names.walletName, in: namespace.id)

            SensitiveText(viewModel.balance)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .matchedGeometryEffect(id: namespace.names.walletBalance, in: namespace.id)
        }
    }

    private var amountContent: some View {
        VStack(spacing: 18) {
            TokenIcon(tokenIconInfo: viewModel.tokenIconInfo, size: CGSize(width: 36, height: 36))
                .matchedGeometryEffect(id: namespace.names.tokenIcon, in: namespace.id)

            VStack(spacing: 6) {
                SendDecimalNumberTextField(viewModel: viewModel.decimalNumberTextFieldViewModel)
                    .initialFocusBehavior(.immediateFocus)
                    .alignment(.center)
                    .prefixSuffixOptions(viewModel.currentFieldOptions)
                    .minTextScale(amountMinTextScale)
                    .matchedGeometryEffect(id: namespace.names.amountCryptoText, in: namespace.id)

                // Keep empty text so that the view maintains its place in the layout
                Text(viewModel.alternativeAmount ?? " ")
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: namespace.names.amountFiatText, in: namespace.id)

                Text(viewModel.error ?? " ")
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
                    .lineLimit(1)
            }
        }
    }

    private var segmentControl: some View {
        GeometryReader { proxy in
            HStack(spacing: 8) {
                SendCurrencyPicker(
                    data: viewModel.currencyPickerData,
                    useFiatCalculation: viewModel.isFiatCalculation.asBinding
                )

                MainButton(title: Localization.sendMaxAmount, style: .secondary) {
                    viewModel.userDidTapMaxAmount()
                }
                .frame(width: proxy.size.width / 3)
            }
        }
    }

    init(
        viewModel: SendAmountViewModel,
        namespace: Namespace
    ) {
        self.viewModel = viewModel
        self.namespace = namespace
    }
}

extension SendAmountView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any SendAmountViewGeometryEffectNames
    }
}

// MARK: - Setupable protocol conformance

extension SendAmountView: Setupable {
    func amountMinTextScale(_ amountMinTextScale: CGFloat?) -> Self {
        map { $0.amountMinTextScale = amountMinTextScale }
    }
}

/*
 struct SendAmountView_Previews: PreviewProvider {
     static let viewModel = SendAmountViewModel(
         inputModel: SendDependenciesBuilder (userWalletName: "Wallet", wallet: .mockETH).makeStakingAmountInput(),
         cryptoFiatAmountConverter: .init(),
         input: StakingAmountInputMock(),
         output: StakingAmountOutputMock()
     )

     @Namespace static var namespace

     static var previews: some View {
         ZStack {
             Colors.Background.tertiary.ignoresSafeArea()

             SendAmountView(
                 viewModel: viewModel,
                 namespace: .init(id: namespace, names: StakingViewNamespaceID())
             )
         }
     }
 }
 */
