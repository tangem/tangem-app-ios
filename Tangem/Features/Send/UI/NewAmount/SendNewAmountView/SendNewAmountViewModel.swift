//
//  SendNewAmountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization
import struct TangemUI.TokenIconInfo

class SendNewAmountViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var cryptoTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var cryptoTextFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published var fiatTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var fiatTextFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published var alternativeAmount: String

    @Published var bottomInfoText: BottomInfoTextType?
    @Published var amountType: SendAmountCalculationType = .crypto

    @Published var receivedTokenViewType: ReceivedTokenViewType?

    lazy var tokenWithAmountViewData: SendNewAmountTokenViewData = .init(
        tokenIconInfo: tokenIconInfo,
        title: tokenItem.name,
        subtitle: balanceFormatted,
        detailsType: .max { [weak self] in
            self?.userDidTapMaxAmount()
        }
    )

    var useFiatCalculation: Bool {
        get { amountType == .fiat }
        set { amountType = newValue ? .fiat : .crypto }
    }

    var tokenCurrencySymbol: String {
        tokenItem.currencySymbol
    }

    var cryptoIconURL: URL? {
        tokenIconInfo.imageURL
    }

    let walletHeaderText: String
    let fiatIconURL: URL?
    let possibleToChangeAmountType: Bool

    // MARK: - Router

    weak var router: SendNewAmountRoutable?

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let tokenIconInfo: TokenIconInfo
    private let balanceFormatted: String
    private let fiatCurrencyCode: String
    private let interactor: SendNewAmountInteractor
    private let analyticsLogger: SendAnalyticsLogger
    private let actionType: SendFlowActionType
    private let sendAmountFormatter: SendAmountFormatter

    private var bag: Set<AnyCancellable> = []

    init(
        sourceTokenInput: SendSourceTokenInput,
        settings: Settings,
        interactor: SendNewAmountInteractor,
        analyticsLogger: SendAnalyticsLogger
    ) {
        walletHeaderText = sourceTokenInput.sourceToken.wallet
        tokenItem = sourceTokenInput.sourceToken.tokenItem
        balanceFormatted = Localization.commonCryptoFiatFormat(
            sourceTokenInput.sourceToken.availableBalanceProvider.formattedBalanceType.value,
            sourceTokenInput.sourceToken.fiatAvailableBalanceProvider.formattedBalanceType.value
        )

        tokenIconInfo = sourceTokenInput.sourceToken.tokenIconInfo
        fiatIconURL = sourceTokenInput.sourceToken.fiatItem.iconURL
        fiatCurrencyCode = sourceTokenInput.sourceToken.fiatItem.currencyCode
        possibleToChangeAmountType = settings.possibleToChangeAmountType
        actionType = settings.actionType

        cryptoTextFieldViewModel = .init(maximumFractionDigits: sourceTokenInput.sourceToken.tokenItem.decimalCount)
        fiatTextFieldViewModel = .init(maximumFractionDigits: SendAmountStep.Constants.fiatMaximumFractionDigits)

        let prefixSuffixOptionsFactory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory()
        cryptoTextFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(cryptoCurrencyCode: sourceTokenInput.sourceToken.tokenItem.currencySymbol)
        fiatTextFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions(fiatCurrencyCode: sourceTokenInput.sourceToken.fiatItem.currencyCode)

        sendAmountFormatter = .init(tokenItem: sourceTokenInput.sourceToken.tokenItem, fiatItem: sourceTokenInput.sourceToken.fiatItem)
        alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: .none, type: .crypto)

        self.interactor = interactor
        self.analyticsLogger = analyticsLogger

        bind()
    }

    func onAppear() {}

    func userDidTapMaxAmount() {
        analyticsLogger.logTapMaxAmount()

        let amount = try? interactor.updateToMaxAmount()
        FeedbackGenerator.success()
        updateAmountsUI(amount: amount)
    }

    func userDidTapReceivedTokenSelection() {
        router?.openReceiveTokensList()
    }

    func removeReceivedToken() {
        interactor.removeReceivedToken()
    }
}

// MARK: - Private

private extension SendNewAmountViewModel {
    func bind() {
        $amountType
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amountType in
                viewModel.update(amountType: amountType)
            }
            .store(in: &bag)

        Publishers.Merge(
            cryptoTextFieldViewModel.valuePublisher,
            fiatTextFieldViewModel.valuePublisher
        )
        .withWeakCaptureOf(self)
        .receive(on: DispatchQueue.main)
        .sink { viewModel, value in
            viewModel.textFieldValueDidChanged(amount: value)
        }
        .store(in: &bag)

        interactor
            .infoTextPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.bottomInfoText, on: self, ownership: .weak)
            .store(in: &bag)

        Publishers.CombineLatest(
            interactor.receivedTokenPublisher,
            interactor.receivedTokenAmountPublisher,
        )
        .withWeakCaptureOf(self)
        .receive(on: DispatchQueue.main)
        .sink { viewModel, args in
            let (token, amount) = args
            viewModel.updateReceivedToken(receiveToken: token, amount: amount)
        }
        .store(in: &bag)
    }

    func textFieldValueDidChanged(amount: Decimal?) {
        let amount = try? interactor.update(amount: amount)
        alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: amount, type: amountType)

        // Update another text field value
        switch amount?.type {
        case .typical(_, let fiat):
            fiatTextFieldViewModel.update(value: fiat)
        case .alternative(_, let crypto):
            cryptoTextFieldViewModel.update(value: crypto)
        case .none:
            cryptoTextFieldViewModel.update(value: nil)
            fiatTextFieldViewModel.update(value: nil)
        }
    }

    func update(amountType: SendAmountCalculationType) {
        let amount = try? interactor.update(type: amountType)
        updateAmountsUI(amount: amount)
    }

    func updateAmountsUI(amount: SendAmount?) {
        cryptoTextFieldViewModel.update(value: amount?.crypto)
        fiatTextFieldViewModel.update(value: amount?.fiat)

        alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: amount, type: amountType)
    }
}

// MARK: - Express

extension SendNewAmountViewModel {
    func updateReceivedToken(receiveToken: SendReceiveTokenType, amount: LoadingResult<SendAmount?, Error>?) {
        guard FeatureProvider.isAvailable(.sendViaSwap) else {
            receivedTokenViewType = .none
            return
        }

        guard interactor.isReceiveTokenSelectionAvailable else {
            receivedTokenViewType = .none
            return
        }

        switch receiveToken {
        case .same:
            receivedTokenViewType = .selectButton
        case .swap(let receiveToken):
            receivedTokenViewType = .selected(SendNewAmountTokenViewData(
                tokenIconInfo: receiveToken.tokenIconInfo,
                title: receiveToken.tokenItem.name,
                subtitle: Localization.sendAmountReceiveTokenSubtitle,
                detailsType: mapToSendNewAmountTokenViewDataDetailsType(amount: amount),
                action: { [weak self] in
                    self?.router?.openReceiveTokensList()
                }
            ))
        }
    }

    func mapToSendNewAmountTokenViewDataDetailsType(amount: LoadingResult<SendAmount?, Error>?) -> SendNewAmountTokenViewData.DetailsType? {
        switch amount {
        case .success(let success):
            // The `individualAction` should be use when the fixed rate will available
            return .select(amount: success?.crypto?.stringValue, individualAction: nil)
        case .none, .failure:
            return nil
        case .loading:
            return .loading
        }
    }
}

// MARK: - SendExternalAmountUpdatableViewModel

extension SendNewAmountViewModel: SendExternalAmountUpdatableViewModel {
    func externalUpdate(amount: SendAmount?) {
        updateAmountsUI(amount: amount)
        textFieldValueDidChanged(amount: amount?.main)
    }
}

// MARK: - SendStepViewAnimatable

extension SendNewAmountViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}

// MARK: - Types

extension SendNewAmountViewModel {
    struct Settings {
        let possibleToChangeAmountType: Bool
        let actionType: SendFlowActionType
    }

    typealias BottomInfoTextType = SendAmountViewModel.BottomInfoTextType

    enum ReceivedTokenViewType {
        case selectButton
        case selected(SendNewAmountTokenViewData)
    }
}
