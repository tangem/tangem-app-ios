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
    @Published var activeField: ActiveAmountField = .source
    @Published var compactSourceSubtitle: SendAmountTokenViewData.SubtitleType?

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
    private weak var receiveAmountOutput: (any SendReceiveTokenAmountOutput)?
    private var lastUpdateSource: UpdateSource?
    private var currentReceiveToken: SendReceiveToken?
    private var balanceFormatter: BalanceFormatter = .init()
    private let balanceConverter = BalanceConverter()
    private let tokenIconInfoBuilder = TokenIconInfoBuilder()

    private var sourceCurrencySymbol: String = ""
    private var bag: Set<AnyCancellable> = []
    private var sourceFieldBag: AnyCancellable?

    init(
        sourceToken: SendSourceToken,
        flowActionType: SendFlowActionType,
        interactor: SendAmountInteractor,
        analyticsLogger: SendAmountAnalyticsLogger,
        receiveAmountOutput: (any SendReceiveTokenAmountOutput)? = nil,
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
        self.receiveAmountOutput = receiveAmountOutput
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
        lastUpdateSource = nil
        activeField = .source
        currentReceiveToken = nil
        compactSourceSubtitle = nil
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
            .infoTextPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, infoText in
                if viewModel.receiveAmountField?.bottomInfoText != nil {
                    viewModel.sourceAmountField.bottomInfoText = nil
                } else {
                    viewModel.sourceAmountField.bottomInfoText = infoText
                }
            }
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
        sourceAmountField.alternativeAmount = sourceAmountField.sendAmountFormatter.formattedAlternative(sendAmount: amount, type: sourceAmountField.amountType)

        // Update another text field value
        switch amount?.type {
        case .typical(_, let fiat):
            sourceAmountField.fiatTextFieldViewModel.update(value: fiat)
        case .alternative(_, let crypto):
            sourceAmountField.cryptoTextFieldViewModel.update(value: crypto)
        case .none:
            sourceAmountField.cryptoTextFieldViewModel.update(value: nil)
            sourceAmountField.fiatTextFieldViewModel.update(value: nil)
        }
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

                // Update compact source subtitle based on loading state
                switch amount {
                case .loading:
                    compactSourceSubtitle = .receive(state: .loading)
                case .success:
                    if let crypto = sourceAmountField.cryptoTextFieldViewModel.value {
                        let formatted = balanceFormatter.formatCryptoBalance(crypto, currencyCode: sourceCurrencySymbol)
                        compactSourceSubtitle = .receive(state: .loaded(text: "\(Localization.sendFromTitle) \(formatted)"))
                    } else {
                        compactSourceSubtitle = nil
                    }
                case .failure:
                    compactSourceSubtitle = nil
                }

                let expandedReceiveData = SendAmountTokenViewData(
                    tokenIconInfo: receiveTokenIconInfo,
                    title: receiveToken.tokenItem.name,
                    subtitle: .receive(state: .loaded(text: Localization.sendAmountReceiveTokenSubtitle)),
                    detailsType: .select(individualAction: nil),
                    action: { [weak self] in
                        self?.router?.openReceiveTokensList()
                    }
                )

                let compactReceiveData = SendAmountTokenViewData(
                    tokenIconInfo: receiveTokenIconInfo,
                    title: receiveToken.tokenItem.name,
                    subtitle: mapToSendAmountTokenViewDataSubtitleType(tokenItem: receiveToken.tokenItem, amount: amount),
                    detailsType: .none
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
                    field.bottomInfoText = nil
                } else if case .failure(let error) = amount,
                          let sendAmountError = error as? SendAmountError,
                          case .receiveRestriction(let restriction) = sendAmountError {
                    updateReceiveRestriction(restriction, token: receiveToken)
                } else {
                    field.bottomInfoText = nil
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
            self?.lastUpdateSource = .receive
            self?.receiveAmountOutput?.receiveAmountDidChanged(amount: value.map { SendAmount(type: .typical(crypto: $0, fiat: nil)) })
        }

        receiveAmountField = field
        return field
    }

    private func updateReceiveRestriction(_ restriction: ReceiveAmountRestriction, token: SendReceiveToken) {
        let symbol = token.tokenItem.currencySymbol
        switch restriction {
        case .tooSmallAmount(let amount):
            let formatted = balanceFormatter.formatCryptoBalance(amount, currencyCode: symbol)
            receiveAmountField?.bottomInfoText = .error(Localization.warningExpressTooMinimalAmountTitle(formatted))
        case .tooBigAmount(let amount):
            let formatted = balanceFormatter.formatCryptoBalance(amount, currencyCode: symbol)
            receiveAmountField?.bottomInfoText = .error(Localization.warningExpressTooMaximumAmountTitle(formatted))
        case .balanceExceeded:
            receiveAmountField?.bottomInfoText = .error(Localization.sendNotificationExceedBalanceTitle)
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
            sourceAmountField.updateAmountsUI(amount: amount)
        } else {
            sourceAmountField.updateAmountsUI(amount: amount)
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
            compactReceiveData: SendAmountTokenViewData
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
