//
//  SendNewAmountInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

protocol SendNewAmountInteractor {
    var infoTextPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> { get }
    var isValidPublisher: AnyPublisher<Bool, Never> { get }

    var receivedTokenPublisher: AnyPublisher<SendReceiveTokenType, Never> { get }
    var receivedTokenAmountPublisher: AnyPublisher<LoadingResult<SendAmount?, Error>, Never> { get }

    func update(amount: Decimal?) throws -> SendAmount?
    func update(type: SendAmountCalculationType) throws -> SendAmount?
    func updateToMaxAmount() throws -> SendAmount

    func removeReceivedToken()
}

class CommonSendNewAmountInteractor {
    private weak var sourceTokenInput: SendSourceTokenInput?
    private weak var sourceTokenAmountInput: SendSourceTokenAmountInput?
    private weak var sourceTokenAmountOutput: SendSourceTokenAmountOutput?

    private weak var receiveTokenInput: SendReceiveTokenInput?
    private weak var receiveTokenOutput: SendReceiveTokenOutput?
    private weak var receiveTokenAmountInput: SendReceiveTokenAmountInput?

    private let validator: SendAmountValidator
    private let amountModifier: SendAmountModifier?
    private let notificationService: SendAmountNotificationService?
    private var type: SendAmountCalculationType

    private var _cachedAmount: CurrentValueSubject<SendAmount?, Never>
    private var _error: CurrentValueSubject<String?, Never> = .init(nil)
    private var _isValid: CurrentValueSubject<Bool, Never> = .init(false)

    private var bag: Set<AnyCancellable> = []

    init(
        sourceTokenInput: any SendSourceTokenInput,
        sourceTokenAmountInput: any SendSourceTokenAmountInput,
        sourceTokenAmountOutput: any SendSourceTokenAmountOutput,
        receiveTokenInput: any SendReceiveTokenInput,
        receiveTokenOutput: any SendReceiveTokenOutput,
        receiveTokenAmountInput: any SendReceiveTokenAmountInput,
        validator: SendAmountValidator,
        amountModifier: SendAmountModifier?,
        notificationService: SendAmountNotificationService?,
        type: SendAmountCalculationType
    ) {
        self.sourceTokenInput = sourceTokenInput
        self.sourceTokenAmountInput = sourceTokenAmountInput
        self.sourceTokenAmountOutput = sourceTokenAmountOutput
        self.receiveTokenInput = receiveTokenInput
        self.receiveTokenOutput = receiveTokenOutput
        self.receiveTokenAmountInput = receiveTokenAmountInput
        self.validator = validator
        self.amountModifier = amountModifier
        self.notificationService = notificationService
        self.type = type

        _cachedAmount = CurrentValueSubject(sourceTokenAmountInput.amount)

        bind()
    }

    private func source() throws -> SendSourceToken {
        guard let sourceTokenInput else {
            throw CommonError.objectReleased
        }

        return sourceTokenInput.sourceToken
    }

    private func bind() {
        _cachedAmount
            .withWeakCaptureOf(self)
            .sink { interactor, amount in
                interactor.validateAndUpdate(amount: amount)
            }
            .store(in: &bag)
    }

    private func validateAndUpdate(amount: SendAmount?) {
        do {
            // Validation is performed only when an initial amount is not empty
            if let crypto = amount?.crypto {
                try validator.validate(amount: crypto)
            }

            let modifiedAmount = try modifyIfNeeded(amount: amount)

            if let modifiedCryptoAmount = modifiedAmount?.crypto, modifiedCryptoAmount != amount?.crypto {
                // additional validation if amount has changed
                try validator.validate(amount: modifiedCryptoAmount)
            }

            update(amount: modifiedAmount, isValid: modifiedAmount != .none, error: .none)
        } catch SendAmountValidatorError.zeroAmount {
            update(amount: .none, isValid: false, error: .none)
        } catch {
            update(amount: .none, isValid: false, error: error)
        }
    }

    private func update(amount: SendAmount?, isValid: Bool, error: Error?) {
        let errorDescription = error.flatMap { getValidationErrorDescription(error: $0) }
        _error.send(errorDescription)
        _isValid.send(isValid)
        sourceTokenAmountOutput?.sourceAmountDidChanged(amount: amount)
    }

    private func getValidationErrorDescription(error: Error) -> String? {
        guard let validationError = error as? ValidationError,
              let source = try? source() else {
            return error.localizedDescription
        }

        let mapper = BlockchainSDKNotificationMapper(tokenItem: source.tokenItem, feeTokenItem: source.feeTokenItem)
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
        switch type {
        case .crypto:
            return .init(type: .typical(crypto: crypto, fiat: fiat))
        case .fiat:
            return .init(type: .alternative(fiat: fiat, crypto: crypto))
        }
    }

    private func convertToCrypto(fiatValue: Decimal?) throws -> Decimal? {
        // If already have the converted the `crypto` amount associated with current `fiat` amount
        if sourceTokenAmountInput?.amount?.fiat == fiatValue {
            return sourceTokenAmountInput?.amount?.crypto
        }

        return try SendAmountConverter().convertToCrypto(fiatValue, tokenItem: source().tokenItem)
    }

    private func convertToFiat(cryptoValue: Decimal?) throws -> Decimal? {
        // If already have the converted the `fiat` amount associated with current `crypto` amount
        if sourceTokenAmountInput?.amount?.crypto == cryptoValue {
            return sourceTokenAmountInput?.amount?.fiat
        }

        return try SendAmountConverter().convertToFiat(cryptoValue, tokenItem: source().tokenItem)
    }
}

// MARK: - SendNewAmountInteractor

extension CommonSendNewAmountInteractor: SendNewAmountInteractor {
    var infoTextPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> {
        let info = amountModifier?.modifyingMessagePublisher ?? .just(output: nil)
        let notification = notificationService?.notificationMessagePublisher ?? .just(output: nil)

        return Publishers.Merge3(
            info.removeDuplicates().map { $0.map { .info($0) } },
            notification.removeDuplicates().map { $0.map { .error($0) } },
            _error.removeDuplicates().map { $0.map { .error($0) } },
        )
        .eraseToAnyPublisher()
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        let emptyNotifications = notificationService?
            .notificationMessagePublisher
            .map { $0 == nil }
            .eraseToAnyPublisher()

        return _isValid
            .combineLatest(emptyNotifications ?? .just(output: true))
            .map { $0 && $1 }
            .eraseToAnyPublisher()
    }

    var receivedTokenPublisher: AnyPublisher<SendReceiveTokenType, Never> {
        guard let receiveTokenInput else {
            return Empty().eraseToAnyPublisher()
        }

        return receiveTokenInput.receiveTokenPublisher
    }

    var receivedTokenAmountPublisher: AnyPublisher<LoadingResult<SendAmount?, Error>, Never> {
        guard let receiveTokenAmountInput else {
            return Empty().eraseToAnyPublisher()
        }

        return receiveTokenAmountInput.receiveAmountPublisher
    }

    func update(amount: Decimal?) throws -> SendAmount? {
        guard let amount else {
            _cachedAmount.send(nil)
            return nil
        }

        let sendAmount: SendAmount = try {
            switch type {
            case .crypto:
                let fiat = try convertToFiat(cryptoValue: amount)
                return makeSendAmount(crypto: amount, fiat: fiat)
            case .fiat:
                let crypto = try convertToCrypto(fiatValue: amount)
                return makeSendAmount(crypto: crypto, fiat: amount)
            }
        }()

        _cachedAmount.send(sendAmount)

        return sendAmount
    }

    func update(type: SendAmountCalculationType) throws -> SendAmount? {
        guard self.type != type else {
            return sourceTokenAmountInput?.amount
        }

        self.type = type
        let sendAmount = _cachedAmount.value?.toggle(type: type)
        validateAndUpdate(amount: sendAmount)
        return sendAmount
    }

    func updateToMaxAmount() throws -> SendAmount {
        let maxAmount = try source().availableBalanceProvider.balanceType.value

        switch type {
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

    func removeReceivedToken() {
        receiveTokenOutput?.userDidRequestClearSelection()
    }
}
