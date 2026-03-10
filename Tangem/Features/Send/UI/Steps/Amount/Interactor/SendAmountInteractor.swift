//
//  SendAmountInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation
import TangemLocalization

protocol SendAmountInteractor {
    var isReceiveTokenSelectionAvailable: Bool { get }
    var sourceFieldInfoPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> { get }
    var receiveFieldInfoPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> { get }
    var isValidPublisher: AnyPublisher<Bool, Never> { get }

    var sourceTokenPublisher: AnyPublisher<LoadingResult<any SendSourceToken, any Error>, Never> { get }

    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, Error>, Never> { get }

    var receivedTokenPublisher: AnyPublisher<LoadingResult<any SendReceiveToken, any Error>, Never> { get }
    var receivedTokenAmountPublisher: AnyPublisher<LoadingResult<SendAmount, Error>, Never> { get }
    var highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never> { get }

    func update(sourceAmount: Decimal?) throws -> SendAmount?
    func update(sourceType: SendAmountCalculationType) throws -> SendAmount?
    func updateToMaxAmount() throws -> SendAmount
    func update(receiveAmount: Decimal?) -> SendAmount?
    func update(receiveType: SendAmountCalculationType)
    /// Validates the source amount populated externally (e.g. from a reverse quote)
    /// without propagating back to the model via `saver`, avoiding a feedback loop.
    func validateExternalSourceAmount(_ amount: SendAmount?)

    func userDidRequestClearReceiveToken()
}

class CommonSendAmountInteractor {
    private weak var sourceTokenInput: SendSourceTokenInput?
    private weak var sourceTokenAmountInput: SendSourceTokenAmountInput?

    private weak var receiveTokenInput: SendReceiveTokenInput?
    private weak var receiveTokenOutput: SendReceiveTokenOutput?
    private weak var receiveTokenAmountInput: SendReceiveTokenAmountInput?
    private weak var receiveTokenAmountOutput: SendReceiveTokenAmountOutput?

    private let validator: SendAmountValidator
    private let amountModifier: SendAmountModifier?
    private let notificationService: SendAmountNotificationService?
    private var saver: SendAmountInteractorSaver
    private var sourceType: SendAmountCalculationType
    private var receiveType: SendAmountCalculationType = .crypto

    private var _cachedAmount: CurrentValueSubject<SendAmount?, Never>
    private var _error: CurrentValueSubject<String?, Never> = .init(nil)
    private var _isValid: CurrentValueSubject<Bool, Never> = .init(false)

    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()
    private lazy var converter = SendAmountConverter()
    private var bag: Set<AnyCancellable> = []

    init(
        sourceTokenInput: any SendSourceTokenInput,
        sourceTokenAmountInput: any SendSourceTokenAmountInput,
        receiveTokenInput: (any SendReceiveTokenInput)?,
        receiveTokenOutput: (any SendReceiveTokenOutput)?,
        receiveTokenAmountInput: (any SendReceiveTokenAmountInput)?,
        receiveTokenAmountOutput: (any SendReceiveTokenAmountOutput)?,
        validator: SendAmountValidator,
        amountModifier: SendAmountModifier?,
        notificationService: SendAmountNotificationService?,
        saver: any SendAmountInteractorSaver,
        sourceType: SendAmountCalculationType = .crypto
    ) {
        self.sourceTokenInput = sourceTokenInput
        self.sourceTokenAmountInput = sourceTokenAmountInput
        self.receiveTokenInput = receiveTokenInput
        self.receiveTokenOutput = receiveTokenOutput
        self.receiveTokenAmountInput = receiveTokenAmountInput
        self.receiveTokenAmountOutput = receiveTokenAmountOutput
        self.validator = validator
        self.amountModifier = amountModifier
        self.notificationService = notificationService
        self.saver = saver
        self.sourceType = sourceType

        _cachedAmount = CurrentValueSubject(sourceTokenAmountInput.sourceAmount.value)

        bind()
    }

    private func source() throws -> SendSourceToken {
        guard let sourceTokenInput else {
            throw CommonError.objectReleased
        }

        return try sourceTokenInput.sourceToken.get()
    }

    private func bind() {
        _cachedAmount
            .withWeakCaptureOf(self)
            .tryMap { try $0.modifyIfNeeded(amount: $1) }
            .replaceError(with: .none)
            .withWeakCaptureOf(self)
            .sink { $0.validateAndUpdate(amount: $1) }
            .store(in: &bag)
    }

    private func validateAndUpdate(amount: SendAmount?) {
        do {
            // Validation is performed only when an initial amount is not empty
            if let crypto = amount?.crypto {
                try validator.validate(amount: crypto)
            }

            update(amount: amount, isValid: amount != .none, error: .none)
        } catch SendAmountValidatorError.zeroAmount {
            update(amount: .none, isValid: false, error: .none)
        } catch {
            update(amount: amount, isValid: false, error: error)
        }
    }

    private func update(amount: SendAmount?, isValid: Bool, error: Error?) {
        let errorDescription = error.flatMap { getValidationErrorDescription(error: $0) }
        _error.send(errorDescription)
        _isValid.send(isValid)
        saver.update(amount: amount)
    }

    private func getValidationErrorDescription(error: Error) -> String? {
        guard let validationError = error as? ValidationError,
              let source = try? source() else {
            return error.localizedDescription
        }

        let mapper = BlockchainSDKNotificationMapper(tokenItem: source.tokenItem)
        if case .string(let title) = mapper.mapToValidationErrorEvent(validationError).title {
            return title
        }

        let description = mapper.mapToValidationErrorEvent(validationError).description
        return description
    }

    private func modifyIfNeeded(amount: SendAmount?) throws -> SendAmount? {
        guard let crypto = amountModifier?.modify(cryptoAmount: amount?.crypto) else {
            return amount
        }

        let fiat = try convertToFiat(cryptoValue: crypto)
        return makeSendAmount(crypto: crypto, fiat: fiat)
    }

    private func makeSendAmount(crypto: Decimal?, fiat: Decimal?) -> SendAmount {
        switch sourceType {
        case .crypto:
            return .init(type: .typical(crypto: crypto, fiat: fiat))
        case .fiat:
            return .init(type: .alternative(fiat: fiat, crypto: crypto))
        }
    }

    private func convertToCrypto(fiatValue: Decimal?) throws -> Decimal? {
        // If already have the converted the `crypto` amount associated with current `fiat` amount
        if sourceTokenAmountInput?.sourceAmount.value?.fiat == fiatValue {
            return sourceTokenAmountInput?.sourceAmount.value?.crypto
        }

        return try converter.convertToCrypto(fiatValue, tokenItem: source().tokenItem)
    }

    private func convertToFiat(cryptoValue: Decimal?) throws -> Decimal? {
        // If already have the converted the `fiat` amount associated with current `crypto` amount
        if sourceTokenAmountInput?.sourceAmount.value?.crypto == cryptoValue {
            return sourceTokenAmountInput?.sourceAmount.value?.fiat
        }

        return try converter.convertToFiat(cryptoValue, tokenItem: source().tokenItem)
    }

    private func receivedTokenAmountValidPublisher() -> AnyPublisher<Bool, Never> {
        guard let receiveTokenInput, let receiveTokenAmountInput else {
            return .just(output: true)
        }

        return Publishers.CombineLatest(
            receiveTokenInput.receiveTokenPublisher,
            receiveTokenAmountInput.receiveAmountPublisher
        ).map { token, amount in
            switch (token.value, amount) {
            case (.none, _), (.some, .success): true
            case (.some, .loading), (.some, .failure): false
            }
        }
        .eraseToAnyPublisher()
    }

    private var validatorInfoPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> {
        let info = amountModifier?.modifyingMessagePublisher ?? .just(output: nil)
        let notification = notificationService?.notificationMessagePublisher ?? .just(output: nil)

        return Publishers.Merge3(
            info.removeDuplicates().map { $0.map { .info($0) } },
            notification.removeDuplicates().map { $0.map { .error($0) } },
            _error.removeDuplicates().map { $0.map { .error($0) } }
        )
        .eraseToAnyPublisher()
    }

    private var sourceRestrictionInfoPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> {
        guard let receiveTokenAmountInput, let sourceTokenInput else {
            return .just(output: nil)
        }

        return Publishers.CombineLatest(
            receiveTokenAmountInput.receiveRestrictionPublisher,
            sourceTokenInput.sourceTokenPublisher
        )
        .map { [weak self] restriction, tokenResult -> SendAmountViewModel.BottomInfoTextType? in
            guard let self, let restriction, let token = tokenResult.value else { return nil }
            return mapRestrictionToInfoText(restriction, tokenItem: token.tokenItem, calculationType: sourceType)
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }

    private var receiveRestrictionInfoPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> {
        guard let receiveTokenAmountInput, let receiveTokenInput else {
            return .just(output: nil)
        }

        return Publishers.CombineLatest(
            receiveTokenAmountInput.receiveRestrictionPublisher,
            receiveTokenInput.receiveTokenPublisher
        )
        .map { [weak self] restriction, tokenResult -> SendAmountViewModel.BottomInfoTextType? in
            guard let self, let restriction, let token = tokenResult.value else { return nil }
            return mapRestrictionToInfoText(restriction, tokenItem: token.tokenItem, calculationType: receiveType)
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }

    private func mapRestrictionToInfoText(
        _ restriction: ReceiveAmountRestriction,
        tokenItem: TokenItem,
        calculationType: SendAmountCalculationType
    ) -> SendAmountViewModel.BottomInfoTextType {
        switch restriction {
        case .tooSmallAmount(let amount):
            // Round UP so the displayed minimum is always sufficient after conversion
            let formatted = formatRestrictionAmount(amount, tokenItem: tokenItem, calculationType: calculationType, roundingMode: .up)
            return .error(Localization.warningExpressTooMinimalAmountTitle(formatted))
        case .tooBigAmount(let amount):
            // Round DOWN so the displayed maximum is always achievable after conversion
            let formatted = formatRestrictionAmount(amount, tokenItem: tokenItem, calculationType: calculationType, roundingMode: .down)
            return .error(Localization.warningExpressTooMaximumAmountTitle(formatted))
        case .balanceExceeded:
            return .error(Localization.sendNotificationExceedBalanceTitle)
        }
    }

    private func formatRestrictionAmount(
        _ cryptoAmount: Decimal,
        tokenItem: TokenItem,
        calculationType: SendAmountCalculationType,
        roundingMode: NSDecimalNumber.RoundingMode
    ) -> String {
        switch calculationType {
        case .crypto:
            var options = BalanceFormattingOptions.defaultCryptoFormattingOptions
            options.roundingType = .default(roundingMode: roundingMode, scale: options.maxFractionDigits)
            return balanceFormatter.formatCryptoBalance(cryptoAmount, currencyCode: tokenItem.currencySymbol, formattingOptions: options)
        case .fiat:
            guard let currencyId = tokenItem.currencyId,
                  let rawFiat = balanceConverter.convertToFiat(cryptoAmount, currencyId: currencyId) else {
                return balanceFormatter.formatCryptoBalance(cryptoAmount, currencyCode: tokenItem.currencySymbol)
            }
            var options = BalanceFormattingOptions.defaultFiatFormattingOptions
            options.roundingType = .default(roundingMode: roundingMode, scale: 2)
            return balanceFormatter.formatFiatBalance(rawFiat, formattingOptions: options)
        }
    }
}

// MARK: - SendAmountInteractor

extension CommonSendAmountInteractor: SendAmountInteractor {
    var isReceiveTokenSelectionAvailable: Bool {
        receiveTokenInput?.isReceiveTokenSelectionAvailable ?? false
    }

    var sourceFieldInfoPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> {
        Publishers.CombineLatest(sourceRestrictionInfoPublisher, validatorInfoPublisher)
            .map { restriction, validator in restriction ?? validator }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var receiveFieldInfoPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> {
        receiveRestrictionInfoPublisher
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        Publishers
            .CombineLatest(_isValid, receivedTokenAmountValidPublisher())
            .map { $0 && $1 }
            .eraseToAnyPublisher()
    }

    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, Error>, Never> {
        guard let sourceTokenAmountInput else {
            return Empty().eraseToAnyPublisher()
        }

        return sourceTokenAmountInput.sourceAmountPublisher
    }

    var sourceTokenPublisher: AnyPublisher<LoadingResult<any SendSourceToken, any Error>, Never> {
        guard let sourceTokenInput else {
            return Empty().eraseToAnyPublisher()
        }

        return sourceTokenInput.sourceTokenPublisher.eraseToAnyPublisher()
    }

    var receivedTokenPublisher: AnyPublisher<LoadingResult<any SendReceiveToken, any Error>, Never> {
        guard let receiveTokenInput else {
            return Empty().eraseToAnyPublisher()
        }

        return receiveTokenInput.receiveTokenPublisher
    }

    var receivedTokenAmountPublisher: AnyPublisher<LoadingResult<SendAmount, Error>, Never> {
        guard let receiveTokenAmountInput else {
            return Empty().eraseToAnyPublisher()
        }

        return receiveTokenAmountInput.receiveAmountPublisher
    }

    var highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never> {
        guard let receiveTokenAmountInput else {
            return Empty().eraseToAnyPublisher()
        }

        return receiveTokenAmountInput.highPriceImpactPublisher
    }

    func update(sourceAmount: Decimal?) throws -> SendAmount? {
        guard let sourceAmount else {
            _cachedAmount.send(nil)
            return nil
        }

        let amount: SendAmount = try {
            switch sourceType {
            case .crypto:
                let fiat = try convertToFiat(cryptoValue: sourceAmount)
                return makeSendAmount(crypto: sourceAmount, fiat: fiat)
            case .fiat:
                let crypto = try convertToCrypto(fiatValue: sourceAmount)
                return makeSendAmount(crypto: crypto, fiat: sourceAmount)
            }
        }()

        _cachedAmount.send(amount)

        return amount
    }

    func update(sourceType newSourceType: SendAmountCalculationType) throws -> SendAmount? {
        guard sourceType != newSourceType else {
            return sourceTokenAmountInput?.sourceAmount.value
        }

        sourceType = newSourceType
        let sendAmount = _cachedAmount.value?.toggle(type: newSourceType)
        validateAndUpdate(amount: sendAmount)
        return sendAmount
    }

    func updateToMaxAmount() throws -> SendAmount {
        let maxAmount = try source().availableBalanceProvider.balanceType.value

        switch sourceType {
        case .crypto:
            let fiat = try convertToFiat(cryptoValue: maxAmount)
            let amount = SendAmount(type: .typical(crypto: maxAmount, fiat: fiat))
            _cachedAmount.send(amount)
            return amount
        case .fiat:
            let fiat = try convertToFiat(cryptoValue: maxAmount)
            let amount = SendAmount(type: .alternative(fiat: fiat, crypto: maxAmount))
            _cachedAmount.send(amount)
            return amount
        }
    }

    func update(receiveAmount: Decimal?) -> SendAmount? {
        guard let receiveAmount else {
            receiveTokenAmountOutput?.receiveAmountDidChange(amount: nil)
            return nil
        }

        guard let tokenItem = receiveTokenInput?.receiveToken.value?.tokenItem else {
            receiveTokenAmountOutput?.receiveAmountDidChange(amount: nil)
            return nil
        }

        let amount: SendAmount
        switch receiveType {
        case .crypto:
            let fiat = converter.convertToFiat(receiveAmount, tokenItem: tokenItem)
            amount = SendAmount(type: .typical(crypto: receiveAmount, fiat: fiat))
        case .fiat:
            let crypto = converter.convertToCrypto(receiveAmount, tokenItem: tokenItem)
            amount = SendAmount(type: .alternative(fiat: receiveAmount, crypto: crypto))
        }

        receiveTokenAmountOutput?.receiveAmountDidChange(amount: amount)
        return amount
    }

    func update(receiveType: SendAmountCalculationType) {
        self.receiveType = receiveType
    }

    func validateExternalSourceAmount(_ amount: SendAmount?) {
        do {
            if let crypto = amount?.crypto {
                try validator.validate(amount: crypto)
            }

            _error.send(nil)
            _isValid.send(amount != nil)
        } catch SendAmountValidatorError.zeroAmount {
            _error.send(nil)
            _isValid.send(false)
        } catch {
            _error.send(getValidationErrorDescription(error: error))
            _isValid.send(false)
        }
    }

    func userDidRequestClearReceiveToken() {
        receiveTokenOutput?.userDidRequestClearSelection()
    }
}
