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
    @Published var compactSendSubtitle: SendAmountTokenViewData.SubtitleType?
    @Published var compactReceiveSubtitle: SendAmountTokenViewData.SubtitleType?
    @Published private(set) var isAccordionSwitchingLocked: Bool = false

    /// Set to `false` before an `activeField` change that should not animate (e.g. first accordion entry).
    /// The view resets it to `true` inside `.onChange(of: activeField)`.
    var animateActiveFieldChange = true

    /// Fires after a short delay when removing the receive token so the view
    /// transfers focus to the source field once the layout has settled.
    @Published var shouldFocusSendField = false

    /// Set to `true` only in `removeReceivedToken` so the accordion→non-accordion
    /// structural change is animated. Entry (non-accordion→accordion) never animates.
    var animateAccordionExit = false

    /// Fires after a delay on first accordion entry so the view claims focus
    /// on the receive field once the token-picker sheet has fully dismissed.
    /// Using `@Published` ensures the view's `.onChange` handler runs in the
    /// live view context, avoiding stale `@FocusState` captures.
    @Published var shouldFocusReceiveField = false

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

    var compactSendTokenViewData: SendAmountTokenViewData? {
        sendAmountTokenViewData.map {
            SendAmountTokenViewData(
                tokenIconInfo: $0.tokenIconInfo,
                title: $0.title,
                subtitle: compactSendSubtitle ?? $0.subtitle,
                detailsType: .none
            )
        }
    }

    var compactReceiveTokenViewData: SendAmountTokenViewData? {
        guard case .accordion(_, let baseCompactData) = receivedTokenViewType else { return nil }
        return SendAmountTokenViewData(
            tokenIconInfo: baseCompactData.tokenIconInfo,
            title: baseCompactData.title,
            subtitle: compactReceiveSubtitle ?? baseCompactData.subtitle,
            detailsType: baseCompactData.detailsType,
            action: baseCompactData.action
        )
    }

    private let flowActionType: SendFlowActionType
    private let interactor: SendAmountInteractor
    private let analyticsLogger: SendAmountAnalyticsLogger
    private var lastUpdateSource: ActiveAmountField?
    private var currentReceiveToken: SendReceiveToken?
    /// Guards against stale CombineLatest emissions after removal.
    /// Set in `removeReceivedToken`, cleared in `case .none:` of `updateReceivedToken`.
    private var isReceiveTokenClearing = false
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
        isReceiveTokenClearing = true
        animateAccordionExit = true
        receiveAmountField = nil
        receiveFieldBag = nil
        lastUpdateSource = nil
        activeField = .send
        receivedTokenViewType = .selectButton
        currentReceiveToken = nil
        compactSendSubtitle = nil
        compactReceiveSubtitle = nil
        interactor.userDidRequestClearReceiveToken()

        // Short delay for the source field to appear in the hierarchy
        // after transitioning from collapsed accordion to expanded.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.shouldFocusSendField = true
        }
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
            isReceiveTokenClearing = false
            receivedTokenViewType = .selectButton
            currentReceiveToken = nil
            compactReceiveSubtitle = nil
        case .some(let receiveToken):
            guard !isReceiveTokenClearing else { return }
            let receiveTokenIconInfo = tokenIconInfoBuilder.build(from: receiveToken.tokenItem, isCustom: receiveToken.isCustom)

            if isFixedRateMode {
                let isFirstSelection = currentReceiveToken == nil
                let tokenDidChange = currentReceiveToken?.tokenItem.id != receiveToken.tokenItem.id
                currentReceiveToken = receiveToken

                let field = receiveAmountField ?? createReceiveAmountField(for: receiveToken, tokenIconInfo: receiveTokenIconInfo)

                // Only rebuild accordion structure when the token itself changes,
                // NOT on every amount update. This prevents view re-creation that
                // clears @FocusState during the focus-claim window.
                if tokenDidChange {
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

                    if isFirstSelection {
                        // Disable animation BEFORE any @Published changes so the
                        // `.animation(_, value:)` modifier reads `false` during render.
                        animateActiveFieldChange = false
                    }

                    receivedTokenViewType = .accordion(
                        expandedReceiveData: expandedReceiveData,
                        compactReceiveData: compactReceiveData
                    )

                    if isFirstSelection {
                        activeField = .receive

                        // Delay until the token-picker sheet finishes dismissing,
                        // then trigger the view's `.onChange` to claim focus.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                            self?.shouldFocusReceiveField = true
                        }
                    }
                }

                // Always update the compact subtitle separately (drives compactReceiveTokenViewData)
                compactReceiveSubtitle = mapToSendAmountTokenViewDataSubtitleType(tokenItem: receiveToken.tokenItem, amount: amount)

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
            compactSendSubtitle = .balance(state: .loading())
        case .success(let amount):
            if let crypto = amount.crypto {
                let formatted = balanceFormatter.formatCryptoBalance(crypto, currencyCode: sourceCurrencySymbol)
                compactSendSubtitle = .balance(state: .loaded(text: "\(Localization.sendFromTitle) \(formatted)"))
            } else {
                compactSendSubtitle = nil
            }
        case .failure:
            compactSendSubtitle = nil
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

        var isAccordion: Bool {
            if case .accordion = self { return true }
            return false
        }
    }
}
