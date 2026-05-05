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

    /// Returns `true` only when the flow type represents a swap AND we actually have a receive
    /// token destination (i.e. the user selected a swap pair).  This guards against
    /// `SendWithSwapFlowFactory` powering a plain send while its flow type is `.sendViaSwap`.
    var isActualSwapFlow: Bool {
        flowActionType.isSwapFlow && receiveSmallAmountViewModel != nil
    }

    @Published private var tokenHeader: SendTokenHeader?
    @Published private var tokenIconInfo: TokenIconInfo?
    @Published private var amountText: String?
    @Published private var alternativeAmount: String?

    @Published private var receiveSmallAmountViewModel: SendAmountFinishSmallAmountViewModel?
    @Published private var sendSwapProviderFinishViewModel: SendSwapProviderFinishViewModel?

    let flowActionType: SendFlowActionType

    private let tokenIconInfoBuilder = TokenIconInfoBuilder()
    private let balanceFormatter = BalanceFormatter()
    private var bag: Set<AnyCancellable> = []

    init(
        flowActionType: SendFlowActionType,
        sourceTokenInput: SendSourceTokenInput,
        sourceTokenAmountInput: SendSourceTokenAmountInput,
        receiveTokenInput: SendReceiveTokenInput? = nil,
        receiveTokenAmountInput: SendReceiveTokenAmountInput? = nil,
        swapProvidersInput: SendSwapProvidersInput? = nil,
        isReceiveAmountApproximatePublisher: AnyPublisher<Bool, Never>? = nil
    ) {
        self.flowActionType = flowActionType
        bind(
            flowActionType: flowActionType,
            sourceTokenInput: sourceTokenInput,
            sourceTokenAmountInput: sourceTokenAmountInput,
            receiveTokenInput: receiveTokenInput,
            receiveTokenAmountInput: receiveTokenAmountInput,
            swapProvidersInput: swapProvidersInput,
            isReceiveAmountApproximatePublisher: isReceiveAmountApproximatePublisher
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
        swapProvidersInput: SendSwapProvidersInput?,
        isReceiveAmountApproximatePublisher: AnyPublisher<Bool, Never>?
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

        guard let receiveTokenInput,
              let receiveTokenAmountInput,
              let swapProvidersInput,
              let isReceiveAmountApproximatePublisher else {
            return
        }

        Publishers.CombineLatest3(
            receiveTokenInput.receiveTokenPublisher,
            receiveTokenAmountInput.receiveAmountPublisher,
            isReceiveAmountApproximatePublisher
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { viewModel, args in
            let (receiveToken, receiveAmount, isApproximateAmount) = args
            viewModel.updateView(
                receiveToken: receiveToken.value,
                flowActionType: flowActionType,
                receiveAmount: receiveAmount,
                isApproximateAmount: isApproximateAmount
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
        tokenHeader = makeFinishTokenHeader(from: sourceToken.header, flowActionType: flowActionType)
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
            let header: SendTokenHeader = {
                if flowActionType == .swap, let token = token as? SendSourceToken {
                    return makeFinishTokenHeader(from: token.header, flowActionType: flowActionType, isSource: false)
                }
                return .action(name: Localization.sendWithSwapRecipientAmountSuccessTitle)
            }()

            let tokenIconInfo = tokenIconInfoBuilder.build(from: token.tokenItem, isCustom: token.isCustom)
            let formattedAmount = receiveAmount.crypto.map {
                SendCryptoValueFormatter(
                    decimals: token.tokenItem.decimalCount,
                    currencySymbol: token.tokenItem.currencySymbol,
                    trimFractions: false
                ).string(from: $0)
            }

            let showTilde = isApproximateAmount && flowActionType.isSwapFlow && FeatureProvider.isAvailable(.swapInProgressV2)
            let amountText = formattedAmount.map { formatted in showTilde ? "\(AppConstants.tildeSign) \(formatted)" : formatted } ?? ""

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

    private func updateView(sourceToken: SendSourceToken, provider: ExpressAvailableProvider?) {
        guard let provider else {
            sendSwapProviderFinishViewModel = nil
            return
        }

        sendSwapProviderFinishViewModel = .init(tokenItem: sourceToken.tokenItem, provider: provider)
    }

    private func makeFinishTokenHeader(from header: TokenHeader, flowActionType: SendFlowActionType, isSource: Bool = true) -> SendTokenHeader {
        guard FeatureProvider.isAvailable(.swapInProgressV2) else {
            return header.asSendTokenHeader(actionType: flowActionType, isSource: isSource)
        }
        return SendTokenHeaderBuilder(tokenHeader: header, actionType: flowActionType).makeSendTokenHeader(isSource: isSource)
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
