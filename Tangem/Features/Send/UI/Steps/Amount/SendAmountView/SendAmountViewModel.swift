//
//  SendAmountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAssets
import TangemExpress
import TangemFoundation
import TangemLocalization
import TangemAccessibilityIdentifiers
import struct TangemUI.TokenIconInfo

class SendAmountViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var tokenHeader: SendTokenHeader?

    @Published var fiatIconURL: URL?

    let sourceAmountField: AmountInputFieldModel
    @Published var destinationAmountField: AmountInputFieldModel?

    @Published var sourceAmountTokenViewData: SendAmountTokenViewData?

    @Published var destinationTokenViewType: DestinationTokenViewType?
    @Published var activeField: ActiveAmountField = .send
    @Published var compactSourceSubtitle: SendAmountTokenViewData.SubtitleType?
    @Published var compactDestinationSubtitle: SendAmountTokenViewData.SubtitleType?
    @Published private(set) var isInputFieldSwitchingLocked: Bool = false

    /// Gates the `.animation(_, value: activeField)` modifier.
    /// Temporarily set to `false` on first destination entry to prevent animation.
    var animateActiveFieldChange = true

    /// When `true`, the FROM section's token row shows compact data even while expanded.
    /// Used for two-phase animation: Phase 1 swaps data instantly, Phase 2 animates collapse.
    @Published var forceCompactSourceTokenRow = false

    /// Gates the `.animation(_, value: isAmountEditable)` modifier.
    /// Set to `true` in `removeReceivedToken` so the removal animates. Entry never animates.
    var animateDestinationRemoval = false

    /// The single mechanism for driving `@FocusState` from the ViewModel.
    /// The view observes this via `.onChange` and transfers focus accordingly.
    @Published var pendingFocusField: ActiveAmountField?

    var useFiatCalculation: Bool {
        get { sourceAmountField.amountType == .fiat }
        set { sourceAmountField.amountType = newValue ? .fiat : .crypto }
    }

    var useDestinationFiatCalculation: Bool {
        get { destinationAmountField?.amountType == .fiat }
        set { destinationAmountField?.amountType = newValue ? .fiat : .crypto }
    }

    // MARK: - Router

    weak var router: SendAmountStepRoutable?

    // MARK: - Dependencies

    @Published private(set) var providerRateTypes: Set<ExpressProviderRateType> = []

    private var isFixedRateSupportedByProvider: Bool { providerRateTypes.contains(.fixed) }

    @Published private(set) var currentRateType: ExpressProviderRateType?

    private var isReceiveAmountApproximate: Bool {
        currentRateType == .float && lastUpdateSource != .receive
    }

    var compactSourceTokenViewData: SendAmountTokenViewData? {
        sourceAmountTokenViewData.map {
            SendAmountTokenViewData(
                tokenIconInfo: $0.tokenIconInfo,
                title: $0.title,
                subtitle: compactSourceSubtitle ?? $0.subtitle,
                detailsType: .none
            )
        }
    }

    var compactDestinationTokenViewData: SendAmountTokenViewData? {
        guard case .selectedEditableAmount(_, let baseCompactData) = destinationTokenViewType else { return nil }
        return SendAmountTokenViewData(
            tokenIconInfo: baseCompactData.tokenIconInfo,
            title: baseCompactData.title,
            subtitle: compactDestinationSubtitle ?? baseCompactData.subtitle,
            detailsType: baseCompactData.detailsType,
            action: baseCompactData.action
        )
    }

    private let flowActionType: SendFlowActionType
    private let interactor: SendAmountInteractor
    private let analyticsLogger: SendAmountAnalyticsLogger
    private let providerRateTypesPublisher: AnyPublisher<Set<ExpressProviderRateType>, Never>?
    private let currentRateTypePublisher: AnyPublisher<ExpressProviderRateType?, Never>?
    private let selectedExpressProviderPublisher: AnyPublisher<LoadingResult<ExpressAvailableProvider, any Error>?, Never>?

    @Published private var lastUpdateSource: ActiveAmountField?
    private var currentDestinationToken: SendReceiveToken?
    /// Guards against stale CombineLatest emissions after removal.
    /// Set in `removeReceivedToken`, cleared in `case .none:` of `updateReceivedToken`.
    private var isDestinationTokenClearing = false
    /// When true, the next `.success` on the receive amount publisher triggers a reverse
    /// calculation so FROM is recalculated at the fixed rate. Set on destination token change.
    private var pendingReverseRecalculation = false
    private var balanceFormatter: BalanceFormatter = .init()
    private let balanceConverter = BalanceConverter()
    private let tokenIconInfoBuilder = TokenIconInfoBuilder()

    private var sourceCurrencySymbol: String = ""
    private var sourceCryptoBalance: String?
    private var bag: Set<AnyCancellable> = []
    private var sourceFieldBag: AnyCancellable?
    private var destinationFieldBag: AnyCancellable?

    init(
        sourceToken: SendSourceToken,
        flowActionType: SendFlowActionType,
        interactor: SendAmountInteractor,
        analyticsLogger: SendAmountAnalyticsLogger,
        providerRateTypesPublisher: AnyPublisher<Set<ExpressProviderRateType>, Never>? = nil,
        currentRateTypePublisher: AnyPublisher<ExpressProviderRateType?, Never>? = nil,
        selectedExpressProviderPublisher: AnyPublisher<LoadingResult<ExpressAvailableProvider, any Error>?, Never>? = nil
    ) {
        sourceAmountField = AmountInputFieldModel(
            tokenItem: sourceToken.tokenItem,
            fiatItem: sourceToken.fiatItem,
            possibleToConvertToFiat: sourceToken.possibleToConvertToFiat
        )

        self.flowActionType = flowActionType
        self.interactor = interactor
        self.analyticsLogger = analyticsLogger
        self.providerRateTypesPublisher = providerRateTypesPublisher
        self.currentRateTypePublisher = currentRateTypePublisher
        self.selectedExpressProviderPublisher = selectedExpressProviderPublisher
        sourceCurrencySymbol = sourceToken.tokenItem.currencySymbol

        sourceFieldBag = sourceAmountField.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }

        bind()
    }

    func onAppear() {}

    func userDidTapMaxAmount() {
        analyticsLogger.logTapMaxAmount()
        pendingReverseRecalculation = false
        lastUpdateSource = .send

        let amount = try? interactor.updateToMaxAmount()
        FeedbackGenerator.heavy()
        sourceAmountField.updateAmountsUI(amount: amount)
    }

    func userDidTapReceivedTokenSelection() {
        analyticsLogger.logTapConvertToAnotherToken()

        openReceiveTokensList()
    }

    func removeReceivedToken() {
        isDestinationTokenClearing = true
        animateActiveFieldChange = true
        animateDestinationRemoval = true
        forceCompactSourceTokenRow = false
        pendingReverseRecalculation = false
        // Disconnect before nilling to prevent stale async onValueChanged
        // callbacks from interfering with the removal cleanup.
        destinationAmountField?.onValueChanged = nil
        destinationAmountField = nil
        destinationFieldBag = nil
        lastUpdateSource = nil
        activeField = .send
        destinationTokenViewType = .selectButton
        currentDestinationToken = nil
        compactSourceSubtitle = nil
        compactDestinationSubtitle = nil

        providerRateTypes = []
        interactor.userDidRequestClearReceiveToken()

        // Short delay for the source field to appear in the hierarchy
        // after removing the destination field.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.pendingFocusField = .send
        }
    }

    private func openReceiveTokensList() {
        router?.openReceiveTokensList(onDismiss: { [weak self] in
            guard let self, currentDestinationToken == nil else { return }

            // Token picker was dismissed without selection — refocus FROM field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.pendingFocusField = .send
            }
        })
    }

    func userDidTapCompactField(_ tappedField: ActiveAmountField) {
        guard !isInputFieldSwitchingLocked else { return }

        if isFixedRateSupportedByProvider, activeField == tappedField.opposite {
            let field = amountField(for: tappedField)

            // Read the value matching the field's current calculation type (crypto or fiat)
            // so the interactor interprets it correctly
            let currentValue: Decimal? = switch field.amountType {
            case .crypto: field.cryptoTextFieldViewModel.value
            case .fiat: field.fiatTextFieldViewModel.value
            }

            guard let currentValue else {
                // No value in the tapped field — just switch without recalculation
                forceCompactSourceTokenRow = tappedField != .send
                animateActiveFieldChange = true
                activeField = tappedField
                pendingFocusField = tappedField
                return
            }

            // Phase 1: Instantly swap FROM token row to target state (no animation)
            forceCompactSourceTokenRow = tappedField != .send
            if tappedField != .send {
                compactSourceSubtitle = makeLoadingCompactSourceSubtitle()
            }

            // Phase 2: Animate the collapse/expand after SwiftUI commits Phase 1
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(20)) { [weak self] in
                guard let self else { return }
                animateActiveFieldChange = true
                isInputFieldSwitchingLocked = true
                activeField = tappedField
                pendingFocusField = tappedField
                lastUpdateSource = tappedField

                // Trigger rate recalculation for the tapped field
                switch tappedField {
                case .send:
                    let amount = try? interactor.update(sourceAmount: currentValue)
                    sourceAmountField.updateAmountsUI(amount: amount)
                case .receive:
                    let amount = interactor.update(receiveAmount: currentValue)
                    destinationAmountField?.updateAmountsUI(amount: amount)
                }
            }
        } else {
            animateActiveFieldChange = true
            activeField = tappedField
            pendingFocusField = tappedField
        }
    }

    func amountField(for field: ActiveAmountField) -> AmountInputFieldModel {
        switch field {
        case .send: return sourceAmountField
        case .receive: return destinationAmountField ?? sourceAmountField
        }
    }

    func isFiatMode(for field: ActiveAmountField) -> Bool {
        switch field {
        case .send: return useFiatCalculation
        case .receive: return useDestinationFiatCalculation
        }
    }

    // MARK: - Rate Badges

    var sourceRateBadge: RateBadgeConfig? {
        guard isFixedRateSupportedByProvider else { return nil }
        let isFixed = !providerRateTypes.contains(.float)
        return RateBadgeConfig(
            title: isFixed ? Localization.sendRateIsFixed : Localization.expressFloatingRate,
            icon: isFixed ? Assets.Send.lockMini : Assets.Send.floatingMini,
            action: { [weak self] in self?.openRateInfo(type: isFixed ? .fixed : .floating) }
        )
    }

    var destinationRateBadge: RateBadgeConfig? {
        guard isFixedRateSupportedByProvider else { return nil }
        return RateBadgeConfig(
            title: Localization.sendRateIsFixed,
            icon: Assets.Send.lockMini,
            action: { [weak self] in self?.openRateInfo(type: .fixed) }
        )
    }

    private func openRateInfo(type: RateInfoSheetViewModel.RateType) {
        switch type {
        case .fixed:
            Analytics.log(.sendNoticeFixedRate)
        case .floating:
            Analytics.log(.sendNoticeFloatRate)
        }

        router?.openRateInfoSheet(rateType: type, onDismiss: { [weak self] in
            guard let self else { return }
            pendingFocusField = activeField
        })
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
                viewModel.interactor.validateExternalSourceAmount(amount)
            }
            .store(in: &bag)

        interactor
            .sourceAmountPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                guard viewModel.isFixedRateSupportedByProvider else { return }
                viewModel.updateCompactSourceSubtitle(sourceAmount: result)
            }
            .store(in: &bag)

        Publishers.CombineLatest3(
            interactor.receivedTokenPublisher,
            interactor.receivedTokenAmountPublisher,
            $providerRateTypes
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { viewModel, args in
            let (token, amount, _) = args
            viewModel.updateDestinationToken(destinationToken: token.value, amount: amount)
        }
        .store(in: &bag)

        interactor
            .receiveFieldInfoPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, infoText in
                viewModel.destinationAmountField?.bottomInfoText = infoText
            }
            .store(in: &bag)

        providerRateTypesPublisher?
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, rateTypes in
                viewModel.handleProviderRateTypesChange(rateTypes)
            }
            .store(in: &bag)

        currentRateTypePublisher?
            .receiveOnMain()
            .assign(to: &$currentRateType)

        selectedExpressProviderPublisher?
            .compactMap { $0?.value?.rateType }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.analyticsLogger.logAmountStepReopened()
            }
            .store(in: &bag)
    }

    func handleProviderRateTypesChange(_ rateTypes: Set<ExpressProviderRateType>) {
        guard providerRateTypes != rateTypes else { return }

        let wasFixedSupported = isFixedRateSupportedByProvider
        providerRateTypes = rateTypes

        switch (wasFixedSupported, isFixedRateSupportedByProvider) {
        case (true, false):
            // Transitioning from supported → unsupported: tear down editable TO
            pendingReverseRecalculation = false
            isInputFieldSwitchingLocked = false
            forceCompactSourceTokenRow = false

            if activeField == .receive {
                animateActiveFieldChange = true
                activeField = .send
                pendingFocusField = .send
            }

            destinationAmountField = nil
            destinationFieldBag = nil
            compactSourceSubtitle = nil

            // Reset so the next CombineLatest emission treats it as "token changed"
            // and rebuilds the destination view in non-editable mode
            currentDestinationToken = nil
        case (false, true):
            // Transitioning from unsupported → supported: force rebuild so the
            // next CombineLatest emission creates the editable TO field
            currentDestinationToken = nil
        default:
            break
        }
    }

    func textFieldValueDidChanged(amount: Decimal?) {
        pendingReverseRecalculation = false
        lastUpdateSource = .send
        let amount = try? interactor.update(sourceAmount: amount)
        sourceAmountField.updateAlternativeUI(amount: amount)

        if amount == nil {
            destinationAmountField?.updateAmountsUI(amount: nil)
        }
    }

    func destinationTextFieldValueDidChange(amount: Decimal?) {
        lastUpdateSource = .receive
        let amount = interactor.update(receiveAmount: amount)
        destinationAmountField?.updateAlternativeUI(amount: amount)

        if amount == nil {
            sourceAmountField.updateAlternativeUI(amount: nil)
        }
    }

    func update(amountType: SendAmountCalculationType) {
        let amount = try? interactor.update(sourceType: amountType)
        sourceAmountField.updateAmountsUI(amount: amount)
    }
}

// MARK: - Tokens

extension SendAmountViewModel {
    func updateSourceToken(sourceToken: SendSourceToken) {
        tokenHeader = sourceToken.header.asSendTokenHeader(actionType: flowActionType)
        sourceCurrencySymbol = sourceToken.tokenItem.currencySymbol

        let cryptoBalance = sourceToken.availableBalanceProvider.formattedBalanceType.value
        sourceCryptoBalance = cryptoBalance

        var balanceFormatted = cryptoBalance
        if sourceToken.fiatAvailableBalanceProvider.balanceType.value != nil {
            balanceFormatted += " \(AppConstants.dotSign) \(sourceToken.fiatAvailableBalanceProvider.formattedBalanceType.value)"
        }

        let tokenIconInfo = tokenIconInfoBuilder.build(from: sourceToken.tokenItem, isCustom: sourceToken.isCustom)
        sourceAmountTokenViewData = .init(
            tokenIconInfo: tokenIconInfo,
            title: sourceToken.tokenItem.name,
            subtitle: .balance(state: .loaded(text: .builder(builder: { $0 }, sensitive: balanceFormatted))),
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

    func updateDestinationToken(destinationToken: SendReceiveToken?, amount: LoadingResult<SendAmount, Error>) {
        guard interactor.isReceiveTokenSelectionAvailable else {
            destinationTokenViewType = .none
            return
        }

        guard let destinationToken else {
            clearDestinationToken()
            return
        }

        guard !isDestinationTokenClearing else { return }

        let iconInfo = tokenIconInfoBuilder.build(from: destinationToken.tokenItem, isCustom: destinationToken.isCustom)

        if isFixedRateSupportedByProvider {
            updateEditableDestination(token: destinationToken, iconInfo: iconInfo, amount: amount)
        } else {
            updateStaticDestination(token: destinationToken, iconInfo: iconInfo, amount: amount)
        }
    }

    private func clearDestinationToken() {
        isDestinationTokenClearing = false
        pendingReverseRecalculation = false
        animateDestinationRemoval = false
        destinationTokenViewType = .selectButton
        currentDestinationToken = nil
        compactDestinationSubtitle = nil
    }

    private func updateStaticDestination(
        token: SendReceiveToken,
        iconInfo: TokenIconInfo,
        amount: LoadingResult<SendAmount, Error>
    ) {
        let tokenViewData = SendAmountTokenViewData(
            tokenIconInfo: iconInfo,
            title: token.tokenItem.name,
            subtitle: mapToSendAmountTokenViewDataSubtitleType(tokenItem: token.tokenItem, amount: amount),
            detailsType: .select(individualAction: nil),
            action: { [weak self] in
                self?.openReceiveTokensList()
            }
        )
        destinationTokenViewType = .selected(tokenViewData)
    }

    private func updateEditableDestination(
        token: SendReceiveToken,
        iconInfo: TokenIconInfo,
        amount: LoadingResult<SendAmount, Error>
    ) {
        let isFirstSelection = currentDestinationToken == nil
        let tokenDidChange = currentDestinationToken?.tokenItem.id != token.tokenItem.id
        currentDestinationToken = token

        let field = destinationAmountField ?? createDestinationAmountField(for: token, tokenIconInfo: iconInfo)

        // Only rebuild the destination section when the token itself changes,
        // NOT on every amount update. This prevents view re-creation that
        // clears @FocusState during the focus-claim window.
        if tokenDidChange {
            rebuildEditableDestinationViews(
                token: token,
                iconInfo: iconInfo,
                field: field,
                isFirstSelection: isFirstSelection,
                amount: amount
            )
        }

        updateEditableDestinationAmount(field: field, token: token, amount: amount)
    }

    private func rebuildEditableDestinationViews(
        token: SendReceiveToken,
        iconInfo: TokenIconInfo,
        field: AmountInputFieldModel,
        isFirstSelection: Bool,
        amount: LoadingResult<SendAmount, Error>
    ) {
        if !isFirstSelection {
            field.reconfigure(
                tokenItem: token.tokenItem,
                fiatItem: token.fiatItem,
                possibleToConvertToFiat: token.tokenItem.currencyId != nil
            )
            field.cryptoIconURL = iconInfo.imageURL
        }

        let expandedDestinationData = SendAmountTokenViewData(
            tokenIconInfo: iconInfo,
            title: token.tokenItem.name,
            subtitle: .receive(state: .loaded(text: Localization.sendAmountReceiveTokenSubtitle)),
            detailsType: .select(individualAction: nil),
            action: { [weak self] in
                self?.openReceiveTokensList()
            }
        )

        let compactDestinationData = SendAmountTokenViewData(
            tokenIconInfo: iconInfo,
            title: token.tokenItem.name,
            subtitle: mapToSendAmountTokenViewDataSubtitleType(tokenItem: token.tokenItem, amount: amount),
            detailsType: .none,
            action: { [weak self] in
                FeedbackGenerator.heavy()
                self?.userDidTapCompactField(.receive)
            }
        )

        if isFirstSelection {
            // Suppress expand/collapse animation on first entry.
            // Re-enabled in userDidTapCompactField on first switch.
            animateActiveFieldChange = false
        }

        destinationTokenViewType = .selectedEditableAmount(
            expandedDestinationData: expandedDestinationData,
            compactDestinationData: compactDestinationData
        )

        if isFirstSelection {
            activeField = .receive
            pendingReverseRecalculation = true
            pendingFocusField = .receive
        } else if lastUpdateSource == .receive {
            // Token changed while user was editing TO — trigger reverse
            // calculation with the user's current field value once the
            // pair-change quote completes.
            pendingReverseRecalculation = true
        }
    }

    private func updateEditableDestinationAmount(
        field: AmountInputFieldModel,
        token: SendReceiveToken,
        amount: LoadingResult<SendAmount, Error>
    ) {
        // Always update the compact subtitle separately (drives compactDestinationTokenViewData)
        compactDestinationSubtitle = mapToSendAmountTokenViewDataSubtitleType(
            tokenItem: token.tokenItem,
            amount: amount
        )

        // Update destination fields from external amount
        if case .success(let sendAmount) = amount {
            if pendingReverseRecalculation {
                pendingReverseRecalculation = false
                lastUpdateSource = .receive

                // Populate the field from the forward estimate so the reverse
                // recalculation below uses the fiat-equivalent value for the new token
                field.updateAmountsUI(amount: sendAmount)

                let receiveValue = field.cryptoTextFieldViewModel.value
                _ = interactor.update(receiveAmount: receiveValue)
            } else if lastUpdateSource == .receive {
                // When the user edited the destination (To) field, only update fiat/alternative
                // to avoid overwriting the crypto value the user typed
                field.updateFromExternalAmount(sendAmount, tokenItem: token.tokenItem)
            } else {
                // When the user edited the source (From) field or on initial load,
                // fully update the destination field including the crypto value from the quote
                field.updateAmountsUI(amount: sendAmount)
            }
        }

        // Unlock when destination recalculation finishes (Source→Destination switch)
        if !amount.isLoading, isInputFieldSwitchingLocked, lastUpdateSource == .send {
            isInputFieldSwitchingLocked = false
        }
    }

    private func createDestinationAmountField(
        for destinationToken: SendReceiveToken,
        tokenIconInfo: TokenIconInfo
    ) -> AmountInputFieldModel {
        let field = AmountInputFieldModel(
            tokenItem: destinationToken.tokenItem,
            fiatItem: destinationToken.fiatItem,
            possibleToConvertToFiat: destinationToken.tokenItem.currencyId != nil
        )
        field.cryptoIconURL = tokenIconInfo.imageURL

        field.onValueChanged = { [weak self] value in
            self?.destinationTextFieldValueDidChange(amount: value)
        }

        destinationFieldBag = field.$amountType
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] type in
                self?.interactor.update(receiveType: type)
            }

        destinationAmountField = field
        return field
    }

    func updateCompactSourceSubtitle(sourceAmount: LoadingResult<SendAmount, Error>) {
        switch sourceAmount {
        case .loading:
            compactSourceSubtitle = makeLoadingCompactSourceSubtitle()
        case .success(let amount):
            if let crypto = amount.crypto {
                let formatted = balanceFormatter.formatCryptoBalance(crypto, currencyCode: sourceCurrencySymbol)
                if FeatureProvider.isAvailable(.sendBalanceSendSplitRows), let balance = sourceCryptoBalance {
                    compactSourceSubtitle = .balanceAndSend(
                        balance: .loaded(text: .builder(
                            builder: { Localization.commonBalance($0) },
                            sensitive: balance
                        )),
                        sendLabel: Localization.commonSendColon,
                        sendAmount: .loaded(text: formatted)
                    )
                } else {
                    let sendText = Localization.sendSummaryTitle(formatted)
                    if let balance = sourceCryptoBalance {
                        compactSourceSubtitle = .balance(state: .loaded(text: .builder(
                            builder: { "\($0) \(AppConstants.dotSign) \(sendText)" },
                            sensitive: balance
                        )))
                    } else {
                        compactSourceSubtitle = .balance(state: .loaded(text: sendText))
                    }
                }
            } else {
                compactSourceSubtitle = nil
            }
        case .failure:
            compactSourceSubtitle = nil
        }

        // Unlock when source recalculation finishes (Receive→Source switch)
        if !sourceAmount.isLoading, isInputFieldSwitchingLocked, lastUpdateSource == .receive {
            isInputFieldSwitchingLocked = false
        }
    }

    private func makeLoadingCompactSourceSubtitle() -> SendAmountTokenViewData.SubtitleType {
        if FeatureProvider.isAvailable(.sendBalanceSendSplitRows), let balance = sourceCryptoBalance {
            return .balanceAndSend(
                balance: .loaded(text: .builder(
                    builder: { Localization.commonBalance($0) },
                    sensitive: balance
                )),
                sendLabel: Localization.commonSendColon,
                sendAmount: .loading()
            )
        }
        return .balance(state: .loading())
    }

    func mapToSendAmountTokenViewDataSubtitleType(
        tokenItem: TokenItem,
        amount: LoadingResult<SendAmount, Error>
    ) -> SendAmountTokenViewData.SubtitleType {
        switch amount {
        case .success(let success):
            let formatted = balanceFormatter.formatCryptoBalance(success.crypto, currencyCode: tokenItem.currencySymbol)
            let displayFormatted = isReceiveAmountApproximate ? "\(AppConstants.tildeSign) \(formatted)" : formatted
            return .receive(state: .loaded(text: Localization.sendWithSwapRecipientGetAmount(displayFormatted)))
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

    enum DestinationTokenViewType {
        case selectButton
        case selected(SendAmountTokenViewData)
        case selectedEditableAmount(
            expandedDestinationData: SendAmountTokenViewData,
            compactDestinationData: SendAmountTokenViewData
        )

        var isAmountEditable: Bool {
            if case .selectedEditableAmount = self { return true }
            return false
        }

        var hasDestinationToken: Bool {
            switch self {
            case .selected, .selectedEditableAmount: true
            case .selectButton: false
            }
        }
    }
}
