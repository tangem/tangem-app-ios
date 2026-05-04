//
//  SendAmountFinishViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import TangemUI
import TangemFoundation
import TangemExpress

class SendAmountFinishViewModel: ObservableObject, Identifiable {
    var viewType: ViewType? { getViewType() }

    @Published private var tokenHeader: SendTokenHeader?
    @Published private var tokenIconInfo: TokenIconInfo?
    @Published private var amountText: String?
    @Published private var alternativeAmount: String?

    @Published private var receiveSmallAmountViewModel: SendAmountFinishSmallAmountViewModel?
    @Published private var sendSwapProviderFinishViewModel: SendSwapProviderFinishViewModel?

    let isSwapAwareFlow: Bool
    private let tokenIconInfoBuilder = TokenIconInfoBuilder()
    private let balanceFormatter = BalanceFormatter()
    private var bag: Set<AnyCancellable> = []

    private var useSwapInProgressV2: Bool {
        isSwapAwareFlow && FeatureProvider.isAvailable(.swapInProgressV2)
    }

    init(
        flowActionType: SendFlowActionType,
        isSwapAwareFlow: Bool = false,
        sourceTokenInput: SendSourceTokenInput,
        sourceTokenAmountInput: SendSourceTokenAmountInput,
        receiveTokenInput: SendReceiveTokenInput? = nil,
        receiveTokenAmountInput: SendReceiveTokenAmountInput? = nil,
        swapProvidersInput: SendSwapProvidersInput? = nil,
    ) {
        self.isSwapAwareFlow = isSwapAwareFlow
        bind(
            flowActionType: flowActionType,
            sourceTokenInput: sourceTokenInput,
            sourceTokenAmountInput: sourceTokenAmountInput,
            receiveTokenInput: receiveTokenInput,
            receiveTokenAmountInput: receiveTokenAmountInput,
            swapProvidersInput: swapProvidersInput
        )
    }
}

// MARK: - Private

private extension SendAmountFinishViewModel {
    func getViewType() -> ViewType? {
        guard
            let tokenHeader,
            let tokenIconInfo,
            let amountText
        else {
            return nil
        }

        guard let receiveSmallAmountViewModel, let sendSwapProviderFinishViewModel else {
            return .one(
                .init(
                    tokenHeader: tokenHeader,
                    tokenIconInfo: tokenIconInfo,
                    amountText: amountText,
                    alternativeAmount: alternativeAmount
                )
            )
        }

        return .double(
            source: .init(
                tokenHeader: tokenHeader,
                tokenIconInfo: tokenIconInfo,
                amountText: amountText,
                alternativeAmount: alternativeAmount
            ),
            destination: receiveSmallAmountViewModel,
            provider: sendSwapProviderFinishViewModel
        )
    }

    func bind(
        flowActionType: SendFlowActionType,
        sourceTokenInput: SendSourceTokenInput,
        sourceTokenAmountInput: SendSourceTokenAmountInput,
        receiveTokenInput: SendReceiveTokenInput?,
        receiveTokenAmountInput: SendReceiveTokenAmountInput?,
        swapProvidersInput: SendSwapProvidersInput?
    ) {
        Publishers.CombineLatest(
            sourceTokenInput.sourceTokenPublisher.compactMap { $0.value },
            sourceTokenAmountInput.sourceAmountPublisher
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { viewModel, tuple in
            viewModel.updateView(sourceToken: tuple.0, flowActionType: flowActionType, sourceAmount: tuple.1)
        }
        .store(in: &bag)

        guard let receiveTokenInput, let receiveTokenAmountInput, let swapProvidersInput else {
            return
        }

        Publishers.CombineLatest3(
            receiveTokenInput.receiveTokenPublisher,
            receiveTokenAmountInput.receiveAmountPublisher,
            swapProvidersInput.currentRateTypePublisher
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { viewModel, args in
            let (receiveToken, receiveAmount, currentRateType) = args
            viewModel.updateView(
                receiveToken: receiveToken.value,
                flowActionType: flowActionType,
                receiveAmount: receiveAmount,
                isApproximateAmount: currentRateType == .float
            )
        }
        .store(in: &bag)

        Publishers.CombineLatest(
            sourceTokenInput.sourceTokenPublisher.compactMap { $0.value },
            swapProvidersInput.selectedExpressProviderPublisher.map { $0?.value },
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { $0.updateView(sourceToken: $1.0, provider: $1.1) }
        .store(in: &bag)
    }

    private func updateView(sourceToken: SendSourceToken, flowActionType: SendFlowActionType, sourceAmount: LoadingResult<SendAmount, any Error>) {
        tokenHeader = makeSendTokenHeader(from: sourceToken.header, flowActionType: flowActionType, isSource: true)
        tokenIconInfo = tokenIconInfoBuilder.build(from: sourceToken.tokenItem, isCustom: sourceToken.isCustom)
        alternativeAmount = sourceAmount.value?.formatAlternative(
            currencySymbol: sourceToken.tokenItem.currencySymbol,
            decimalCount: sourceToken.tokenItem.decimalCount
        )

        switch sourceAmount.value?.type {
        case .typical(let crypto, _):
            amountText = crypto.map {
                SendCryptoValueFormatter(
                    decimals: sourceToken.tokenItem.decimalCount,
                    currencySymbol: sourceToken.tokenItem.currencySymbol,
                    trimFractions: false
                ).string(from: $0)
            }
        case .alternative(let fiat, _):
            amountText = fiat.map {
                balanceFormatter.formatFiatBalance($0)
            }
        case nil:
            break
        }
    }

    private func updateView(
        receiveToken: SendReceiveToken?,
        flowActionType: SendFlowActionType,
        receiveAmount: LoadingResult<SendAmount, any Error>,
        isApproximateAmount: Bool
    ) {
        switch (receiveToken, receiveAmount) {
        case (.none, _):
            receiveSmallAmountViewModel = nil
        case (.some(let token), .success(let receiveAmount)):
            let header: SendTokenHeader = if let token = token as? SendSourceToken {
                makeSendTokenHeader(from: token.header, flowActionType: flowActionType, isSource: false)
            } else {
                .action(name: Localization.sendWithSwapRecipientAmountSuccessTitle)
            }

            let tokenIconInfo = tokenIconInfoBuilder.build(from: token.tokenItem, isCustom: token.isCustom)
            let formattedAmount = receiveAmount.crypto.map {
                SendCryptoValueFormatter(
                    decimals: token.tokenItem.decimalCount,
                    currencySymbol: token.tokenItem.currencySymbol,
                    trimFractions: false
                ).string(from: $0)
            }

            let amountText: String = if let formattedAmount, useSwapInProgressV2, isApproximateAmount {
                "\(AppConstants.tildeSign) \(formattedAmount)"
            } else {
                formattedAmount ?? ""
            }

            receiveSmallAmountViewModel = .init(
                tokenHeader: header,
                tokenIconInfo: tokenIconInfo,
                amountText: amountText,
                alternativeAmount: receiveAmount.formatAlternative(
                    currencySymbol: token.tokenItem.currencySymbol,
                    decimalCount: token.tokenItem.decimalCount
                )
            )
        case (.some, .failure), (.some, .loading):
            // Do nothing to avoid incorrect view state
            break
        }
    }

    private func makeSendTokenHeader(from tokenHeader: TokenHeader, flowActionType: SendFlowActionType, isSource: Bool) -> SendTokenHeader {
        guard useSwapInProgressV2 else {
            return tokenHeader.asSendTokenHeader(actionType: flowActionType, isSource: isSource)
        }

        switch tokenHeader {
        case .account(let name, let icon):
            return .account(
                prefix: isSource ? Localization.swappingFromAccountTitle : Localization.swappingToAccountTitle,
                name: name,
                icon: icon
            )
        case .wallet(_, hasOnlyOneWallet: true):
            return .action(name: isSource ? Localization.swappingFromTitleV2 : Localization.swappingToTitle)
        case .wallet(let name, hasOnlyOneWallet: false):
            return .wallet(name: isSource ? Localization.commonFromWalletName(name) : Localization.commonToWalletName(name))
        }
    }

    private func updateView(sourceToken: SendSourceToken, provider: ExpressAvailableProvider?) {
        guard let provider else {
            sendSwapProviderFinishViewModel = nil
            return
        }

        sendSwapProviderFinishViewModel = .init(tokenItem: sourceToken.tokenItem, provider: provider)
    }
}

extension SendAmountFinishViewModel {
    enum ViewType {
        case one(SendAmountFinishLargeAmountViewModel)
        case double(
            source: SendAmountFinishSmallAmountViewModel,
            destination: SendAmountFinishSmallAmountViewModel,
            provider: SendSwapProviderFinishViewModel
        )
    }
}
