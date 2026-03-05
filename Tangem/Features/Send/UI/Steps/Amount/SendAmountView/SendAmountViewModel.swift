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

    @Published var fiatIconURL: URL?

    let sourceAmountField: AmountInputFieldModel
    @Published var receiveAmountField: AmountInputFieldModel?

    @Published var sendAmountTokenViewData: SendAmountTokenViewData?
    @Published var receivedTokenViewType: ReceivedTokenViewType?
    @Published var activeField: ActiveAmountField = .send
    @Published var compactSourceSubtitle: SendAmountTokenViewData.SubtitleType?
    @Published private(set) var isAccordionSwitchingLocked: Bool = false

    var useFiatCalculation: Bool {
        get { sourceAmountField.amountType == .fiat }
        set { sourceAmountField.amountType = newValue ? .fiat : .crypto }
    }

    var useReceiveFiatCalculation: Bool {
        get { receiveAmountField?.amountType == .fiat }
        set { receiveAmountField?.amountType = newValue ? .fiat : .crypto }
    }

    // MARK: - Router

    weak var router: SendAmountStepRoutable?

    // MARK: - Dependencies

    let isFixedRateMode: Bool

    var compactSourceTokenViewData: SendAmountTokenViewData? {
        sendAmountTokenViewData.map {
            SendAmountTokenViewData(
                tokenIconInfo: $0.tokenIconInfo,
                title: $0.title,
                subtitle: compactSourceSubtitle ?? $0.subtitle,
                detailsType: .none
            )
        }
    }

    private let flowActionType: SendFlowActionType
    private let interactor: SendAmountInteractor
    private let analyticsLogger: SendAmountAnalyticsLogger
    private var lastUpdateSource: ActiveAmountField?
    private var currentReceiveToken: SendReceiveToken?
    private var balanceFormatter: BalanceFormatter = .init()
    private let balanceConverter = BalanceConverter()
    private let tokenIconInfoBuilder = TokenIconInfoBuilder()

    private var sourceCurrencySymbol: String = ""
    private var bag: Set<AnyCancellable> = []
    private var sourceFieldBag: AnyCancellable?
    private var receiveFieldBag: AnyCancellable?

    init(
        sourceToken: SendSourceToken,
        flowActionType: SendFlowActionType,
        interactor: SendAmountInteractor,
        analyticsLogger: SendAmountAnalyticsLogger,
        isFixedRateMode: Bool = false
    ) {
        sourceAmountField = AmountInputFieldModel(
            tokenItem: sourceToken.tokenItem,
            fiatItem: sourceToken.fiatItem,
            possibleToConvertToFiat: sourceToken.possibleToConvertToFiat
        )

        self.flowActionType = flowActionType
        self.interactor = interactor
        self.analyticsLogger = analyticsLogger
        self.isFixedRateMode = isFixedRateMode

        sourceFieldBag = sourceAmountField.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }

        bind()
    }

    func onAppear() {}

    func userDidTapMaxAmount() {
        analyticsLogger.logTapMaxAmount()

        let amount = try? interactor.updateToMaxAmount()
        FeedbackGenerator.heavy()
        sourceAmountField.updateAmountsUI(amount: amount)
    }

    func userDidTapReceivedTokenSelection() {
        analyticsLogger.logTapConvertToAnotherToken()

        router?.openReceiveTokensList()
    }

    func removeReceivedToken() {
        receiveAmountField = nil
        receiveFieldBag = nil
        lastUpdateSource = nil
        activeField = .send
        currentReceiveToken = nil
        compactSourceSubtitle = nil
        interactor.userDidRequestClearReceiveToken()
    }

    func userDidTapCompactSource() {
        guard !isAccordionSwitchingLocked else { return }

        if isFixedRateMode, activeField == .receive,
           let currentSourceCrypto = sourceAmountField.cryptoTextFieldViewModel.value {
            isAccordionSwitchingLocked = true
            activeField = .send
            lastUpdateSource = .send
            // Trigger float rate recalculation
            let amount = try? interactor.update(sendAmount: currentSourceCrypto)
            sourceAmountField.updateAmountsUI(amount: amount)
        } else {
            activeField = .send
        }
    }

    func userDidTapCompactReceive() {
        guard !isAccordionSwitchingLocked else { return }

        if isFixedRateMode, activeField == .send,
           let currentReceiveCrypto = receiveAmountField?.cryptoTextFieldViewModel.value {
            isAccordionSwitchingLocked = true
            activeField = .receive
            lastUpdateSource = .receive
            // Trigger fixed rate recalculation
            let amount = interactor.update(receiveAmount: currentReceiveCrypto)
            receiveAmountField?.updateAmountsUI(amount: amount)
        } else {
            activeField = .receive
        }
    }
}

// MARK: - Private

private extension SendAmountViewModel {
    func bind() {
        sourceAmountField.onValueChanged = { [weak self] value in
            self?.textFieldValueDidChanged(amount: value)
        }

        sourceAmountField.$amountType
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amountType in
                viewModel.update(amountType: amountType)
            }
            .store(in: &bag)

        interactor
            .sourceFieldInfoPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, infoText in
                viewModel.sourceAmountField.bottomInfoText = infoText
            }
            .store(in: &bag)

        interactor
            .sourceTokenPublisher
            .compactMap { $0.value }
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.updateSourceToken(sourceToken: $1) }
            .store(in: &bag)

        interactor
            .sourceAmountPublisher
            .compactMap(\.value)
            .removeDuplicates { $0.crypto == $1.crypto }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, amount in
                guard viewModel.lastUpdateSource != .send else { return }
                viewModel.sourceAmountField.updateAmountsUI(amount: amount)
            }
            .store(in: &bag)

        interactor
            .sourceAmountPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                guard viewModel.isFixedRateMode else { return }
                viewModel.updateCompactSourceSubtitle(sourceAmount: result)
            }
            .store(in: &bag)

        Publishers.CombineLatest(
            interactor.receivedTokenPublisher,
            interactor.receivedTokenAmountPublisher,
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { viewModel, args in
            let (token, amount) = args
            viewModel.updateReceivedToken(receiveToken: token.value, amount: amount)
        }
        .store(in: &bag)

        interactor
            .receiveFieldInfoPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, infoText in
                viewModel.receiveAmountField?.bottomInfoText = infoText
            }
            .store(in: &bag)
    }

    func textFieldValueDidChanged(amount: Decimal?) {
        lastUpdateSource = .send
        let amount = try? interactor.update(sendAmount: amount)
        sourceAmountField.updateAlternativeUI(amount: amount)
    }

    func receiveTextFieldValueDidChange(amount: Decimal?) {
        lastUpdateSource = .receive
        let amount = interactor.update(receiveAmount: amount)
        receiveAmountField?.updateAlternativeUI(amount: amount)
    }

    func update(amountType: SendAmountCalculationType) {
        let amount = try? interactor.update(type: amountType)
        sourceAmountField.updateAmountsUI(amount: amount)
    }
}

// MARK: - Tokens

extension SendAmountViewModel {
    func updateSourceToken(sourceToken: SendSourceToken) {
        tokenHeader = sourceToken.header.asSendTokenHeader(actionType: flowActionType)
        sourceCurrencySymbol = sourceToken.tokenItem.currencySymbol

        var balanceFormatted = sourceToken.availableBalanceProvider.formattedBalanceType.value
        if sourceToken.fiatAvailableBalanceProvider.balanceType.value != nil {
            balanceFormatted += " \(AppConstants.dotSign) \(sourceToken.fiatAvailableBalanceProvider.formattedBalanceType.value)"
        }

        let tokenIconInfo = tokenIconInfoBuilder.build(from: sourceToken.tokenItem, isCustom: sourceToken.isCustom)
        sendAmountTokenViewData = .init(
            tokenIconInfo: tokenIconInfo,
            title: sourceToken.tokenItem.name,
            subtitle: .balance(state: .loaded(text: .string(balanceFormatted))),
            detailsType: .max { [weak self] in
                self?.userDidTapMaxAmount()
            }
        )

        sourceAmountField.cryptoIconURL = tokenIconInfo.imageURL
        fiatIconURL = sourceToken.fiatItem.iconURL

        sourceAmountField.reconfigure(
            tokenItem: sourceToken.tokenItem,
            fiatItem: sourceToken.fiatItem,
            possibleToConvertToFiat: sourceToken.possibleToConvertToFiat
        )
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
            let receiveTokenIconInfo = tokenIconInfoBuilder.build(from: receiveToken.tokenItem, isCustom: receiveToken.isCustom)

            if isFixedRateMode {
                let isFirstSelection = currentReceiveToken == nil
                currentReceiveToken = receiveToken

                let expandedReceiveData = SendAmountTokenViewData(
                    tokenIconInfo: receiveTokenIconInfo,
                    title: receiveToken.tokenItem.name,
                    subtitle: .balance(state: .loaded(text: Localization.sendAmountReceiveTokenSubtitle)),
                    detailsType: .select(individualAction: nil),
                    action: { [weak self] in
                        self?.router?.openReceiveTokensList()
                    }
                )

                let compactReceiveData = SendAmountTokenViewData(
                    tokenIconInfo: receiveTokenIconInfo,
                    title: receiveToken.tokenItem.name,
                    subtitle: mapToSendAmountTokenViewDataSubtitleType(tokenItem: receiveToken.tokenItem, amount: amount),
                    detailsType: .none,
                    action: { [weak self] in
                        FeedbackGenerator.heavy()
                        self?.userDidTapCompactReceive()
                    }
                )

                let field = receiveAmountField ?? createReceiveAmountField(for: receiveToken, tokenIconInfo: receiveTokenIconInfo)

                receivedTokenViewType = .accordion(
                    expandedReceiveData: expandedReceiveData,
                    compactReceiveData: compactReceiveData
                )

                if isFirstSelection {
                    activeField = .receive
                }

                // Update receive fields from external amount
                if case .success(let sendAmount) = amount {
                    if lastUpdateSource == .receive {
                        // When the user edited the receive (To) field, only update fiat/alternative
                        // to avoid overwriting the crypto value the user typed
                        field.updateFromExternalAmount(sendAmount, tokenItem: receiveToken.tokenItem)
                    } else {
                        // When the user edited the source (From) field or on initial load,
                        // fully update the receive field including the crypto value from the quote
                        field.updateAmountsUI(amount: sendAmount)
                    }
                }

                // Unlock when receive recalculation finishes (Source→Receive switch)
                if !amount.isLoading, isAccordionSwitchingLocked, lastUpdateSource == .send {
                    isAccordionSwitchingLocked = false
                }
            } else {
                let tokenViewData = SendAmountTokenViewData(
                    tokenIconInfo: receiveTokenIconInfo,
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

    private func createReceiveAmountField(for receiveToken: SendReceiveToken, tokenIconInfo: TokenIconInfo) -> AmountInputFieldModel {
        let field = AmountInputFieldModel(
            tokenItem: receiveToken.tokenItem,
            fiatItem: receiveToken.fiatItem,
            possibleToConvertToFiat: receiveToken.tokenItem.currencyId != nil
        )
        field.cryptoIconURL = tokenIconInfo.imageURL

        field.onValueChanged = { [weak self] value in
            self?.receiveTextFieldValueDidChange(amount: value)
        }

        receiveFieldBag = field.$amountType
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] type in
                self?.interactor.update(receiveType: type)
            }

        receiveAmountField = field
        return field
    }

    func updateCompactSourceSubtitle(sourceAmount: LoadingResult<SendAmount, Error>) {
        switch sourceAmount {
        case .loading:
            compactSourceSubtitle = .balance(state: .loading())
        case .success(let amount):
            if let crypto = amount.crypto {
                let formatted = balanceFormatter.formatCryptoBalance(crypto, currencyCode: sourceCurrencySymbol)
                compactSourceSubtitle = .balance(state: .loaded(text: "\(Localization.sendFromTitle) \(formatted)"))
            } else {
                compactSourceSubtitle = nil
            }
        case .failure:
            compactSourceSubtitle = nil
        }

        // Unlock when source recalculation finishes (Receive→Source switch)
        if !sourceAmount.isLoading, isAccordionSwitchingLocked, lastUpdateSource == .receive {
            isAccordionSwitchingLocked = false
        }
    }

    func mapToSendAmountTokenViewDataSubtitleType(
        tokenItem: TokenItem,
        amount: LoadingResult<SendAmount, Error>
    ) -> SendAmountTokenViewData.SubtitleType {
        switch amount {
        case .success(let success):
            let formatted = balanceFormatter.formatCryptoBalance(success.crypto, currencyCode: tokenItem.currencySymbol)
            return .balance(state: .loaded(text: Localization.sendWithSwapRecipientGetAmount(formatted)))
        case .failure:
            return .balance(state: .loaded(text: Localization.sendAmountReceiveTokenSubtitle))
        case .loading:
            return .balance(state: .loading())
        }
    }
}

// MARK: - SendAmountExternalUpdatableViewModel

extension SendAmountViewModel: SendAmountExternalUpdatableViewModel {
    func externalUpdate(amount: SendAmount?) {
        sourceAmountField.updateAmountsUI(amount: amount)
        textFieldValueDidChanged(amount: amount?.main)
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
            compactReceiveData: SendAmountTokenViewData
        )
    }
}
