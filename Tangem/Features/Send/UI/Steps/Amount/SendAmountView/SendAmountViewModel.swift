//
//  SendAmountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization
import TangemAccessibilityIdentifiers
import struct TangemUI.TokenIconInfo

class SendAmountViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var tokenHeader: SendTokenHeader?
    @Published var possibleToConvertToFiat: Bool = true

    @Published var cryptoIconURL: URL?
    @Published var fiatIconURL: URL?

    @Published var cryptoTextFieldViewModel: DecimalNumberTextFieldViewModel
    @Published var cryptoTextFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published var fiatTextFieldViewModel: DecimalNumberTextFieldViewModel
    @Published var fiatTextFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published var alternativeAmount: String

    @Published var bottomInfoText: BottomInfoTextType?
    @Published var amountType: SendAmountCalculationType = .crypto

    @Published var sendAmountTokenViewData: SendAmountTokenViewData?
    @Published var receivedTokenViewType: ReceivedTokenViewType?
    @Published var activeField: ActiveAmountField = .source
    @Published var receiveTextFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions?
    @Published var receiveFiatText: String?

    var useFiatCalculation: Bool {
        get { amountType == .fiat }
        set { amountType = newValue ? .fiat : .crypto }
    }

    var alternativeAmountAccessibilityIdentifier: String {
        useFiatCalculation
            ? SendAccessibilityIdentifiers.alternativeCryptoAmount
            : SendAccessibilityIdentifiers.alternativeFiatAmount
    }

    // MARK: - Router

    weak var router: SendAmountStepRoutable?

    // MARK: - Dependencies

    @Published var receiveAmountTextFieldViewModel: DecimalNumberTextFieldViewModel?

    let isFixedRateMode: Bool

    var compactSourceTokenViewData: SendAmountTokenViewData? {
        sendAmountTokenViewData.map {
            SendAmountTokenViewData(
                tokenIconInfo: $0.tokenIconInfo,
                title: $0.title,
                subtitle: $0.subtitle,
                detailsType: .none
            )
        }
    }

    private let flowActionType: SendFlowActionType
    private let interactor: SendAmountInteractor
    private let analyticsLogger: SendAmountAnalyticsLogger
    private weak var receiveAmountOutput: (any SendReceiveTokenAmountOutput)?
    private var lastUpdateSource: UpdateSource?
    private var currentReceiveToken: SendReceiveToken?
    private var sendAmountFormatter: SendAmountFormatter
    private var balanceFormatter: BalanceFormatter = .init()
    private let balanceConverter = BalanceConverter()
    private let prefixSuffixOptionsFactory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory()

    private var bag: Set<AnyCancellable> = []

    init(
        sourceToken: SendSourceToken,
        flowActionType: SendFlowActionType,
        interactor: SendAmountInteractor,
        analyticsLogger: SendAmountAnalyticsLogger,
        receiveAmountOutput: (any SendReceiveTokenAmountOutput)? = nil,
        isFixedRateMode: Bool = false
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

        self.flowActionType = flowActionType
        self.interactor = interactor
        self.analyticsLogger = analyticsLogger
        self.receiveAmountOutput = receiveAmountOutput
        self.isFixedRateMode = isFixedRateMode

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
        receiveAmountTextFieldViewModel = nil
        lastUpdateSource = nil
        activeField = .source
        receiveTextFieldOptions = nil
        receiveFiatText = nil
        currentReceiveToken = nil
        interactor.userDidRequestClearReceiveToken()
    }

    func userDidTapCompactSource() {
        activeField = .source
    }

    func userDidTapCompactReceive() {
        activeField = .receive
    }
}

// MARK: - Private

private extension SendAmountViewModel {
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
            .compactMap { $0.value }
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
            viewModel.updateReceivedToken(receiveToken: token.value, amount: amount)
        }
        .store(in: &bag)
    }

    func textFieldValueDidChanged(amount: Decimal?) {
        lastUpdateSource = .source
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

extension SendAmountViewModel {
    func updateSourceToken(sourceToken: SendSourceToken) {
        tokenHeader = sourceToken.header.asSendTokenHeader(actionType: flowActionType)
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
    }

    func updateReceivedToken(receiveToken: SendReceiveToken?, amount: LoadingResult<SendAmount, Error>) {
        guard interactor.isReceiveTokenSelectionAvailable else {
            receivedTokenViewType = .none
            return
        }

        switch receiveToken {
        case .none:
            receivedTokenViewType = .selectButton
        case .some(let receiveToken):
            if isFixedRateMode {
                let isFirstSelection = currentReceiveToken == nil
                currentReceiveToken = receiveToken

                let expandedReceiveData = SendAmountTokenViewData(
                    tokenIconInfo: receiveToken.tokenIconInfo,
                    title: receiveToken.tokenItem.name,
                    subtitle: .receive(state: .loaded(text: Localization.sendAmountReceiveTokenSubtitle)),
                    detailsType: .select(individualAction: nil),
                    action: { [weak self] in
                        self?.router?.openReceiveTokensList()
                    }
                )

                let compactReceiveData = SendAmountTokenViewData(
                    tokenIconInfo: receiveToken.tokenIconInfo,
                    title: receiveToken.tokenItem.name,
                    subtitle: mapToSendAmountTokenViewDataSubtitleType(tokenItem: receiveToken.tokenItem, amount: amount),
                    detailsType: .none
                )

                let textFieldVM = receiveAmountTextFieldViewModel ?? createReceiveAmountTextField(for: receiveToken)
                receiveTextFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(cryptoCurrencyCode: receiveToken.tokenItem.currencySymbol)

                receivedTokenViewType = .accordion(
                    expandedReceiveData: expandedReceiveData,
                    compactReceiveData: compactReceiveData,
                    textFieldVM: textFieldVM
                )

                if isFirstSelection {
                    activeField = .receive
                }

                // Update fiat text from external amount
                if case .success(let sendAmount) = amount {
                    updateReceiveFiatText(crypto: sendAmount.crypto, tokenItem: receiveToken.tokenItem)
                }
            } else {
                let tokenViewData = SendAmountTokenViewData(
                    tokenIconInfo: receiveToken.tokenIconInfo,
                    title: receiveToken.tokenItem.name,
                    subtitle: mapToSendAmountTokenViewDataSubtitleType(tokenItem: receiveToken.tokenItem, amount: amount),
                    detailsType: .select(individualAction: nil),
                    action: { [weak self] in
                        self?.router?.openReceiveTokensList()
                    }
                )
                receivedTokenViewType = .selected(tokenViewData)
            }
        }
    }

    private func createReceiveAmountTextField(for receiveToken: SendReceiveToken) -> DecimalNumberTextFieldViewModel {
        let textFieldVM = DecimalNumberTextFieldViewModel(maximumFractionDigits: receiveToken.tokenItem.decimalCount)
        receiveAmountTextFieldViewModel = textFieldVM

        textFieldVM.valuePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, value in
                viewModel.lastUpdateSource = .receive
                viewModel.receiveAmountDidChange(value)
            }
            .store(in: &bag)

        return textFieldVM
    }

    private func receiveAmountDidChange(_ value: Decimal?) {
        guard let value else {
            receiveAmountOutput?.receiveAmountDidChanged(amount: nil)
            receiveFiatText = nil
            return
        }

        let fiat: Decimal?
        if let currencyId = currentReceiveToken?.tokenItem.currencyId {
            fiat = balanceConverter.convertToFiat(value, currencyId: currencyId)
        } else {
            fiat = nil
        }

        let amount = SendAmount(type: .typical(crypto: value, fiat: fiat))
        receiveAmountOutput?.receiveAmountDidChanged(amount: amount)

        if let fiat {
            receiveFiatText = balanceFormatter.formatFiatBalance(fiat)
        } else {
            receiveFiatText = nil
        }
    }

    private func updateReceiveFiatText(crypto: Decimal?, tokenItem: TokenItem) {
        guard let crypto, let currencyId = tokenItem.currencyId else {
            receiveFiatText = nil
            return
        }

        if let fiat = balanceConverter.convertToFiat(crypto, currencyId: currencyId) {
            receiveFiatText = balanceFormatter.formatFiatBalance(fiat)
        } else {
            receiveFiatText = nil
        }
    }

    func mapToSendAmountTokenViewDataSubtitleType(
        tokenItem: TokenItem,
        amount: LoadingResult<SendAmount, Error>
    ) -> SendAmountTokenViewData.SubtitleType {
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

extension SendAmountViewModel: SendAmountExternalUpdatableViewModel {
    func externalUpdate(amount: SendAmount?) {
        if isFixedRateMode, lastUpdateSource == .receive {
            // When the user typed a receive amount, update source fields with the calculated source amount
            updateAmountsUI(amount: amount)
        } else {
            updateAmountsUI(amount: amount)
            textFieldValueDidChanged(amount: amount?.main)
        }
    }
}

// MARK: - Types

extension SendAmountViewModel {
    enum BottomInfoTextType: Hashable {
        case info(String)
        case error(String)
    }

    enum ReceivedTokenViewType {
        case selectButton
        case selected(SendAmountTokenViewData)
        case accordion(
            expandedReceiveData: SendAmountTokenViewData,
            compactReceiveData: SendAmountTokenViewData,
            textFieldVM: DecimalNumberTextFieldViewModel
        )
    }

    enum ActiveAmountField: Hashable {
        case source
        case receive
    }

    enum UpdateSource {
        case source
        case receive
    }
}
