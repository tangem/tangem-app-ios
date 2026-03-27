//
//  CommonSendAmountSwapHandler.swift
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
import struct TangemUI.TokenIconInfo

final class CommonSendAmountSwapHandler: SendAmountSwapHandler {
    // MARK: - Internal State

    @Published private var providerRateTypes: Set<ExpressProviderRateType> = []
    @Published private(set) var lastUpdateSource: ActiveAmountField?

    private var isFixedRateSupportedByProvider: Bool { providerRateTypes.contains(.fixed) }

    private var currentDestinationToken: (any SendReceiveToken)?
    private var isDestinationTokenClearing = false
    private var pendingReverseRecalculation = false

    // MARK: - Dependencies

    private unowned var viewModel: SendAmountViewModel!
    private let interactor: SendAmountInteractor
    private let analyticsLogger: SendAmountAnalyticsLogger
    private let providerRateTypesPublisher: AnyPublisher<Set<ExpressProviderRateType>, Never>

    private let balanceFormatter = BalanceFormatter()
    private let tokenIconInfoBuilder = TokenIconInfoBuilder()

    private var bag: Set<AnyCancellable> = []
    private var destinationFieldBag: AnyCancellable?

    // MARK: - Init

    init(
        interactor: SendAmountInteractor,
        analyticsLogger: SendAmountAnalyticsLogger,
        providerRateTypesPublisher: AnyPublisher<Set<ExpressProviderRateType>, Never>
    ) {
        self.interactor = interactor
        self.analyticsLogger = analyticsLogger
        self.providerRateTypesPublisher = providerRateTypesPublisher
    }

    // MARK: - SendAmountSwapHandler

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

    var isReceiveAmountApproximatePublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest($lastUpdateSource, $providerRateTypes)
            .map { source, rateTypes in !rateTypes.contains(.fixed) || source == .send }
            .eraseToAnyPublisher()
    }

    func bind(to viewModel: SendAmountViewModel) {
        self.viewModel = viewModel

        providerRateTypesPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { handler, rateTypes in
                handler.handleProviderRateTypesChange(rateTypes)
            }
            .store(in: &bag)

        Publishers.CombineLatest3(
            interactor.receivedTokenPublisher,
            interactor.receivedTokenAmountPublisher,
            $providerRateTypes
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { handler, args in
            let (token, amount, _) = args
            handler.updateDestinationToken(token: token.value, amount: amount)
        }
        .store(in: &bag)

        interactor
            .receiveFieldInfoPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { handler, infoText in
                handler.viewModel.destinationAmountField?.bottomInfoText = infoText
            }
            .store(in: &bag)

        interactor
            .sourceAmountPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { handler, result in
                handler.handleExternalSourceAmount(result)
            }
            .store(in: &bag)
    }

    // MARK: - User Actions

    func userDidTapCompactField(_ field: ActiveAmountField) {
        guard !viewModel.isInputFieldSwitchingLocked else { return }

        if isFixedRateSupportedByProvider, viewModel.activeField == field.opposite {
            let amountField = amountField(for: field)

            let currentValue: Decimal? = switch amountField.amountType {
            case .crypto: amountField.cryptoTextFieldViewModel.value
            case .fiat: amountField.fiatTextFieldViewModel.value
            }

            guard let currentValue else {
                viewModel.forceCompactSourceTokenRow = field != .send
                viewModel.animateActiveFieldChange = true
                viewModel.activeField = field
                viewModel.pendingFocusField = field
                return
            }

            // Phase 1: Instantly swap FROM token row to target state (no animation)
            viewModel.forceCompactSourceTokenRow = field != .send
            if field != .send {
                viewModel.compactSourceSubtitle = .balance(state: .loading())
            }

            // Phase 2: Animate the collapse/expand after SwiftUI commits Phase 1
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(20)) { [weak self] in
                guard let self else { return }
                viewModel.animateActiveFieldChange = true
                viewModel.isInputFieldSwitchingLocked = true
                viewModel.activeField = field
                viewModel.pendingFocusField = field
                lastUpdateSource = field

                switch field {
                case .send:
                    let amount = try? interactor.update(sourceAmount: currentValue)
                    viewModel.sourceAmountField.updateAmountsUI(amount: amount)
                case .receive:
                    let amount = interactor.update(receiveAmount: currentValue)
                    viewModel.destinationAmountField?.updateAmountsUI(amount: amount)
                }
            }
        } else {
            viewModel.animateActiveFieldChange = true
            viewModel.activeField = field
            viewModel.pendingFocusField = field
        }
    }

    func userDidTapReceivedTokenSelection() {
        openReceiveTokensList()
    }

    func removeReceivedToken() {
        isDestinationTokenClearing = true
        viewModel.animateActiveFieldChange = true
        viewModel.animateDestinationRemoval = true
        viewModel.forceCompactSourceTokenRow = false
        viewModel.destinationAmountField = nil
        destinationFieldBag = nil
        lastUpdateSource = nil
        viewModel.activeField = .send
        viewModel.destinationTokenViewType = .selectButton
        currentDestinationToken = nil
        viewModel.compactSourceSubtitle = nil
        viewModel.compactDestinationSubtitle = nil

        providerRateTypes = []
        interactor.userDidRequestClearReceiveToken()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.viewModel.pendingFocusField = .send
        }
    }

    // MARK: - Data Updates

    func sourceTextFieldValueDidChange(amount: Decimal?) {
        lastUpdateSource = .send
    }

    func handleExternalSourceAmount(_ result: LoadingResult<SendAmount, Error>) {
        guard isFixedRateSupportedByProvider else { return }
        updateCompactSourceSubtitle(sourceAmount: result)
    }

    func updateDestinationToken(token: (any SendReceiveToken)?, amount: LoadingResult<SendAmount, Error>) {
        guard interactor.isReceiveTokenSelectionAvailable else {
            viewModel.destinationTokenViewType = .none
            return
        }

        guard let token else {
            clearDestinationToken()
            return
        }

        guard !isDestinationTokenClearing else { return }

        let iconInfo = tokenIconInfoBuilder.build(from: token.tokenItem, isCustom: token.isCustom)

        if isFixedRateSupportedByProvider {
            updateEditableDestination(token: token, iconInfo: iconInfo, amount: amount)
        } else {
            updateStaticDestination(token: token, iconInfo: iconInfo, amount: amount)
        }
    }

    // MARK: - Field Queries

    func amountField(for field: ActiveAmountField) -> AmountInputFieldModel {
        switch field {
        case .send: return viewModel.sourceAmountField
        case .receive: return viewModel.destinationAmountField ?? viewModel.sourceAmountField
        }
    }

    func isFiatMode(for field: ActiveAmountField) -> Bool {
        switch field {
        case .send: return viewModel.useFiatCalculation
        case .receive: return viewModel.useDestinationFiatCalculation
        }
    }
}

// MARK: - Private

private extension CommonSendAmountSwapHandler {
    func handleProviderRateTypesChange(_ rateTypes: Set<ExpressProviderRateType>) {
        guard providerRateTypes != rateTypes else { return }

        let wasFixedSupported = isFixedRateSupportedByProvider
        providerRateTypes = rateTypes

        switch (wasFixedSupported, isFixedRateSupportedByProvider) {
        case (true, false):
            // Transitioning from supported -> unsupported: tear down editable TO
            pendingReverseRecalculation = false
            viewModel.isInputFieldSwitchingLocked = false
            viewModel.forceCompactSourceTokenRow = false

            if viewModel.activeField == .receive {
                viewModel.animateActiveFieldChange = true
                viewModel.activeField = .send
                viewModel.pendingFocusField = .send
            }

            viewModel.destinationAmountField = nil
            destinationFieldBag = nil
            viewModel.compactSourceSubtitle = nil

            // Reset so the next CombineLatest emission treats it as "token changed"
            // and rebuilds the destination view in non-editable mode
            currentDestinationToken = nil
        case (false, true):
            // Transitioning from unsupported -> supported: force rebuild so the
            // next CombineLatest emission creates the editable TO field
            currentDestinationToken = nil
        default:
            break
        }
    }

    func clearDestinationToken() {
        isDestinationTokenClearing = false
        pendingReverseRecalculation = false
        viewModel.animateDestinationRemoval = false
        viewModel.destinationTokenViewType = .selectButton
        currentDestinationToken = nil
        viewModel.compactDestinationSubtitle = nil
    }

    func updateStaticDestination(
        token: some SendReceiveToken,
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
        viewModel.destinationTokenViewType = .selected(tokenViewData)
    }

    func updateEditableDestination(
        token: some SendReceiveToken,
        iconInfo: TokenIconInfo,
        amount: LoadingResult<SendAmount, Error>
    ) {
        let isFirstSelection = currentDestinationToken == nil
        let tokenDidChange = currentDestinationToken?.tokenItem.id != token.tokenItem.id
        currentDestinationToken = token

        let field = viewModel.destinationAmountField ?? createDestinationAmountField(for: token, tokenIconInfo: iconInfo)

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

    func rebuildEditableDestinationViews(
        token: some SendReceiveToken,
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
                self?.viewModel.userDidTapCompactField(.receive)
            }
        )

        if isFirstSelection {
            // Suppress expand/collapse animation on first entry.
            // Re-enabled in userDidTapCompactField on first switch.
            viewModel.animateActiveFieldChange = false
        }

        viewModel.destinationTokenViewType = .selectedEditableAmount(
            expandedDestinationData: expandedDestinationData,
            compactDestinationData: compactDestinationData
        )

        if isFirstSelection {
            viewModel.activeField = .receive
            pendingReverseRecalculation = true
            viewModel.pendingFocusField = .receive
        } else if lastUpdateSource == .receive {
            // Token changed while user was editing TO -- trigger reverse
            // calculation with the user's current field value once the
            // pair-change quote completes
            pendingReverseRecalculation = true
        }
    }

    func updateEditableDestinationAmount(
        field: AmountInputFieldModel,
        token: some SendReceiveToken,
        amount: LoadingResult<SendAmount, Error>
    ) {
        // Always update the compact subtitle separately (drives compactDestinationTokenViewData)
        viewModel.compactDestinationSubtitle = mapToSendAmountTokenViewDataSubtitleType(
            tokenItem: token.tokenItem,
            amount: amount
        )

        // Update destination fields from external amount
        if case .success(let sendAmount) = amount {
            if pendingReverseRecalculation {
                pendingReverseRecalculation = false
                lastUpdateSource = .receive

                // If the field is empty (first selection), populate from the forward quote
                if field.cryptoTextFieldViewModel.value == nil {
                    field.updateAmountsUI(amount: sendAmount)
                }

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

        // Unlock when destination recalculation finishes (Source->Destination switch)
        if !amount.isLoading, viewModel.isInputFieldSwitchingLocked, lastUpdateSource == .send {
            viewModel.isInputFieldSwitchingLocked = false
        }
    }

    func createDestinationAmountField(
        for destinationToken: some SendReceiveToken,
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

        viewModel.destinationAmountField = field
        return field
    }

    func destinationTextFieldValueDidChange(amount: Decimal?) {
        lastUpdateSource = .receive
        let amount = interactor.update(receiveAmount: amount)
        viewModel.destinationAmountField?.updateAlternativeUI(amount: amount)

        if amount == nil {
            viewModel.sourceAmountField.updateAlternativeUI(amount: nil)
        }
    }

    func updateCompactSourceSubtitle(sourceAmount: LoadingResult<SendAmount, Error>) {
        switch sourceAmount {
        case .loading:
            viewModel.compactSourceSubtitle = .balance(state: .loading())
        case .success(let amount):
            if let crypto = amount.crypto {
                let formatted = balanceFormatter.formatCryptoBalance(crypto, currencyCode: viewModel.sourceCurrencySymbol)
                let sendText = Localization.sendSummaryTitle(formatted)
                if let balance = viewModel.sourceCryptoBalance {
                    viewModel.compactSourceSubtitle = .balance(state: .loaded(text: .builder(
                        builder: { "\($0) \(AppConstants.dotSign) \(sendText)" },
                        sensitive: balance
                    )))
                } else {
                    viewModel.compactSourceSubtitle = .balance(state: .loaded(text: sendText))
                }
            } else {
                viewModel.compactSourceSubtitle = nil
            }
        case .failure:
            viewModel.compactSourceSubtitle = nil
        }

        // Unlock when source recalculation finishes (Receive->Source switch)
        if !sourceAmount.isLoading, viewModel.isInputFieldSwitchingLocked, lastUpdateSource == .receive {
            viewModel.isInputFieldSwitchingLocked = false
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

    func openReceiveTokensList() {
        viewModel.router?.openReceiveTokensList(onDismiss: { [weak self] in
            guard let self, currentDestinationToken == nil else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.viewModel.pendingFocusField = .send
            }
        })
    }

    func openRateInfo(type: RateInfoSheetViewModel.RateType) {
        viewModel.router?.openRateInfoSheet(rateType: type, onDismiss: { [weak self] in
            guard let self else { return }
            viewModel.pendingFocusField = viewModel.activeField
        })
    }
}
