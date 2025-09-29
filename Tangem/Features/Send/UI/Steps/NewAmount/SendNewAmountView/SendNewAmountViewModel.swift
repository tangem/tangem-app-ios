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

    @Published var walletHeaderText: String = ""
    @Published var possibleToConvertToFiat: Bool = true

    @Published var cryptoIconURL: URL?
    @Published var fiatIconURL: URL?

    @Published var cryptoTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var cryptoTextFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published var fiatTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var fiatTextFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published var alternativeAmount: String

    @Published var bottomInfoText: BottomInfoTextType?
    @Published var amountType: SendAmountCalculationType = .crypto

    @Published var sendAmountTokenViewData: SendNewAmountTokenViewData?
    @Published var receivedTokenViewType: ReceivedTokenViewType?

    var useFiatCalculation: Bool {
        get { amountType == .fiat }
        set { amountType = newValue ? .fiat : .crypto }
    }

    // MARK: - Router

    weak var router: SendNewAmountRoutable?

    // MARK: - Dependencies

    private let interactor: SendNewAmountInteractor
    private let analyticsLogger: SendAnalyticsLogger
    private var sendAmountFormatter: SendAmountFormatter
    private var balanceFormatter: BalanceFormatter = .init()
    private let prefixSuffixOptionsFactory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory()

    private var bag: Set<AnyCancellable> = []

    init(
        sourceToken: SendSourceToken,
        interactor: SendNewAmountInteractor,
        analyticsLogger: SendAnalyticsLogger
    ) {
        cryptoTextFieldViewModel = .init(maximumFractionDigits: sourceToken.tokenItem.decimalCount)
        cryptoTextFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(cryptoCurrencyCode: sourceToken.tokenItem.currencySymbol)

        fiatTextFieldViewModel = .init(maximumFractionDigits: sourceToken.fiatItem.fractionDigits)
        fiatTextFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions(fiatCurrencyCode: sourceToken.fiatItem.currencyCode)

        sendAmountFormatter = .init(
            tokenItem: sourceToken.tokenItem,
            fiatItem: sourceToken.fiatItem,
            balanceFormatter: balanceFormatter
        )

        alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: .none, type: .crypto)

        self.interactor = interactor
        self.analyticsLogger = analyticsLogger

        bind()
    }

    func onAppear() {}

    func userDidTapMaxAmount() {
        analyticsLogger.logTapMaxAmount()

        let amount = try? interactor.updateToMaxAmount()
        FeedbackGenerator.heavy()
        updateAmountsUI(amount: amount)
    }

    func userDidTapReceivedTokenSelection() {
        analyticsLogger.logTapConvertToAnotherToken()

        router?.openReceiveTokensList()
    }

    func removeReceivedToken() {
        interactor.userDidRequestClearReceiveToken()
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

        interactor
            .sourceTokenPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { $0.updateSourceToken(sourceToken: $1) }
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

// MARK: - Tokens

extension SendNewAmountViewModel {
    func updateSourceToken(sourceToken: SendSourceToken) {
        walletHeaderText = Localization.sendFromWalletName(sourceToken.wallet)
        possibleToConvertToFiat = sourceToken.possibleToConvertToFiat

        var balanceFormatted = sourceToken.availableBalanceProvider.formattedBalanceType.value
        if sourceToken.fiatAvailableBalanceProvider.balanceType.value != nil {
            balanceFormatted += " \(AppConstants.dotSign) \(sourceToken.fiatAvailableBalanceProvider.formattedBalanceType.value)"
        }

        sendAmountTokenViewData = .init(
            tokenIconInfo: sourceToken.tokenIconInfo,
            title: sourceToken.tokenItem.name,
            subtitle: .balance(state: .loaded(text: .string(balanceFormatted))),
            detailsType: .max { [weak self] in
                self?.userDidTapMaxAmount()
            }
        )

        cryptoIconURL = sourceToken.tokenIconInfo.imageURL
        fiatIconURL = sourceToken.fiatItem.iconURL

        cryptoTextFieldViewModel.update(maximumFractionDigits: sourceToken.tokenItem.decimalCount)
        cryptoTextFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(cryptoCurrencyCode: sourceToken.tokenItem.currencySymbol)

        fiatTextFieldViewModel.update(maximumFractionDigits: sourceToken.fiatItem.fractionDigits)
        fiatTextFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions(fiatCurrencyCode: sourceToken.fiatItem.currencyCode)

        sendAmountFormatter = .init(tokenItem: sourceToken.tokenItem, fiatItem: sourceToken.fiatItem, balanceFormatter: balanceFormatter)
        alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: .none, type: .crypto)
    }

    func updateReceivedToken(receiveToken: SendReceiveTokenType, amount: LoadingResult<SendAmount, Error>) {
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
                subtitle: mapToSendNewAmountTokenViewDataSubtitleType(tokenItem: receiveToken.tokenItem, amount: amount),
                // The `individualAction` should be use when the fixed rate will available
                detailsType: .select(individualAction: nil),
                action: { [weak self] in
                    self?.router?.openReceiveTokensList()
                }
            ))
        }
    }

    func mapToSendNewAmountTokenViewDataSubtitleType(
        tokenItem: TokenItem,
        amount: LoadingResult<SendAmount, Error>
    ) -> SendNewAmountTokenViewData.SubtitleType {
        switch amount {
        case .success(let success):
            let formatted = balanceFormatter.formatCryptoBalance(success.crypto, currencyCode: tokenItem.currencySymbol)
            return .receive(state: .loaded(text: Localization.sendWithSwapRecipientGetAmount(formatted)))
        case .failure:
            return .receive(state: .loaded(text: Localization.sendAmountReceiveTokenSubtitle))
        case .loading:
            return .receive(state: .loading)
        }
    }
}

// MARK: - SendAmountExternalUpdatableViewModel

extension SendNewAmountViewModel: SendAmountExternalUpdatableViewModel {
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
    typealias BottomInfoTextType = SendAmountViewModel.BottomInfoTextType

    enum ReceivedTokenViewType {
        case selectButton
        case selected(SendNewAmountTokenViewData)
    }
}
