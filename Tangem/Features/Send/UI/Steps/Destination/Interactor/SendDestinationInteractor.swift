//
//  CommonSendDestinationInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import BlockchainSdk

protocol SendDestinationInteractor {
    var tokenItemPublisher: AnyPublisher<TokenItem, Never> { get }
    var suggestedWalletsPublisher: AnyPublisher<[SendDestinationSuggestedWallet], Never> { get }
    var transactionHistoryPublisher: AnyPublisher<[SendDestinationSuggestedTransactionRecord], Never> { get }

    var destinationResolvedAddress: AnyPublisher<String?, Never> { get }
    var isValidatingDestination: AnyPublisher<Bool, Never> { get }
    var canEmbedAdditionalField: AnyPublisher<Bool, Never> { get }
    var destinationValid: AnyPublisher<Bool, Never> { get }
    var allFieldsIsValid: AnyPublisher<Bool, Never> { get }
    var destinationError: AnyPublisher<String?, Never> { get }
    var destinationAdditionalFieldError: AnyPublisher<String?, Never> { get }

    func shouldResolve(address: String) -> Bool

    @MainActor
    func update(destination: String, source: Analytics.DestinationAddressSource) async
    func update(additionalField: String)

    func preloadTransactionHistoryIfNeeded()
}

class CommonSendDestinationInteractor {
    private let initialSourceToken: SendSourceToken
    private weak var input: SendDestinationInput?
    private weak var receiveTokenInput: SendReceiveTokenInput?

    private var saver: SendDestinationInteractorSaver
    private var dependenciesBuilder: SendDestinationInteractorDependenciesProvider
    private let validateMemoBeforeConfirm: Bool

    private let _isValidatingDestination: CurrentValueSubject<Bool, Never> = .init(false)
    private let _canEmbedAdditionalField: CurrentValueSubject<Bool, Never> = .init(true)

    private let _destinationValid: CurrentValueSubject<Bool, Never> = .init(false)
    private let _destinationError: CurrentValueSubject<Error?, Never> = .init(nil)

    private let _additionalFieldValid: CurrentValueSubject<Bool, Never> = .init(true)
    private let _destinationAdditionalFieldError: CurrentValueSubject<Error?, Never> = .init(nil)

    private let _suggestedWallets: CurrentValueSubject<[SendDestinationSuggestedWallet], Never> = .init([])
    private let _suggestedDestination: CurrentValueSubject<[SendDestinationSuggestedTransactionRecord], Never> = .init([])

    private var bag: Set<AnyCancellable> = []

    init(
        initialSourceToken: SendSourceToken,
        input: SendDestinationInput,
        receiveTokenInput: SendReceiveTokenInput?,
        saver: SendDestinationInteractorSaver,
        dependenciesBuilder: SendDestinationInteractorDependenciesProvider,
        validateMemoBeforeConfirm: Bool = FeatureProvider.isAvailable(.memoValidationBeforeConfirm)
    ) {
        self.initialSourceToken = initialSourceToken
        self.input = input
        self.receiveTokenInput = receiveTokenInput
        self.saver = saver
        self.dependenciesBuilder = dependenciesBuilder
        self.validateMemoBeforeConfirm = validateMemoBeforeConfirm

        bind()
    }

    private func bind() {
        // Fallback publisher is used to trigger dependencies update once on initialization if `receiveTokenInput` is nil
        let receiveTokenPublisher = receiveTokenInput?
            .receiveTokenPublisher
            .eraseToOptional()
            .eraseToAnyPublisher() ?? .just(output: nil)

        receiveTokenPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { $0.updateDependencies(receivedToken: $1?.value) }
            .store(in: &bag)

        bindMemoRevalidation()
    }

    private func updateDependencies(receivedToken: SendReceiveToken?) {
        dependenciesBuilder.update(receivedToken: receivedToken)

        _suggestedWallets.send(dependenciesBuilder.suggestedWallets)
        dependenciesBuilder.transactionHistoryProvider
            .transactionHistoryPublisher
            .assign(to: \._suggestedDestination.value, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func update(destination result: Result<SendDestination?, Error>, source: Analytics.DestinationAddressSource) {
        switch result {
        case .success(.some(let address)) where address.value.typedAddress.isEmpty:
            fallthrough

        case .success(.none):
            _destinationValid.send(false)
            _destinationError.send(.none)
            saver.update(address: .none)

        case .success(.some(let address)):
            _destinationValid.send(true)
            _destinationError.send(.none)
            dependenciesBuilder.analyticsLogger.logSendAddressEntered(isAddressValid: true, addressSource: source)
            saver.update(address: address)

        case .failure(let error):
            _destinationValid.send(false)
            _destinationError.send(error)
            dependenciesBuilder.analyticsLogger.logSendAddressEntered(isAddressValid: false, addressSource: source)
            saver.update(address: .none)
        }
    }

    private func proceed(additionalField: String) throws -> SendDestinationAdditionalField {
        guard let type = dependenciesBuilder.additionalFieldType else {
            assertionFailure("Additional field for the blockchain which doesn't support it")
            return .notSupported
        }

        do {
            let parameters = try dependenciesBuilder.parametersBuilder.transactionParameters(value: additionalField)
            return .filled(type: type, value: additionalField, params: parameters)
        } catch TransactionParamsBuilderError.extraIdNotSupported {
            // We don't have to call this code if transactionParameters doesn't exist for this blockchain
            // Check your input parameters
            assertionFailure("Additional field for the blockchain which doesn't support it")
            return .notSupported
        } catch {
            // the AdditionalField value is wrong
            throw error
        }
    }
}

// MARK: - Memo Requirement Validation

private extension CommonSendDestinationInteractor {
    func bindMemoRevalidation() {
        guard validateMemoBeforeConfirm else { return }

        // Re-validate additional field when destination changes (memoRequired flag may change)
        input?.destinationPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { interactor, _ in interactor.revalidateAdditionalFieldIfNeeded() }
            .store(in: &bag)
    }

    func isMemoRequiredForCurrentDestination() -> Bool {
        guard let destination = input?.destination else {
            return false
        }

        switch destination.value {
        case .resolved(_, _, memoRequired: true):
            return true
        case .plain, .resolved:
            return false
        }
    }

    func applyMemoValidationIfEnabled() {
        if validateMemoBeforeConfirm {
            applyMemoRequirementValidation()
        } else {
            _destinationAdditionalFieldError.send(nil)
            _additionalFieldValid.send(true)
        }
    }

    func applyMemoRequirementValidation() {
        guard isMemoRequiredForCurrentDestination() else {
            _destinationAdditionalFieldError.send(nil)
            _additionalFieldValid.send(true)
            return
        }
        _destinationAdditionalFieldError.send(SendAddressServiceError.additionalFieldRequired)
        _additionalFieldValid.send(false)
    }

    func revalidateAdditionalFieldIfNeeded() {
        guard let additionalField = input?.destinationAdditionalField else {
            return
        }

        // Don't override format/params errors on destination changes.
        // Only revalidate when there is no error yet, or when the current error is the memo-required one.
        if let error = _destinationAdditionalFieldError.value {
            if let addressError = error as? SendAddressServiceError, case .additionalFieldRequired = addressError {
                // Allow revalidation
            } else {
                return
            }
        }

        // Only re-validate if additional field is empty
        // Non-empty fields are validated by update(additionalField:)
        switch additionalField {
        case .empty:
            applyMemoRequirementValidation()
        case .notSupported, .filled:
            break
        }
    }
}

// MARK: - SendDestinationInteractor

extension CommonSendDestinationInteractor: SendDestinationInteractor {
    var tokenItemPublisher: AnyPublisher<TokenItem, Never> {
        guard let receiveTokenInput else {
            return Empty().eraseToAnyPublisher()
        }

        return receiveTokenInput
            .receiveTokenPublisher
            .withWeakCaptureOf(self)
            .map { $1.value?.tokenItem ?? $0.initialSourceToken.tokenItem }
            .eraseToAnyPublisher()
    }

    var transactionHistoryPublisher: AnyPublisher<[SendDestinationSuggestedTransactionRecord], Never> {
        _suggestedDestination.eraseToAnyPublisher()
    }

    var suggestedWalletsPublisher: AnyPublisher<[SendDestinationSuggestedWallet], Never> {
        _suggestedWallets.eraseToAnyPublisher()
    }

    var destinationResolvedAddress: AnyPublisher<String?, Never> {
        guard let input else {
            return Empty().eraseToAnyPublisher()
        }

        return input.destinationPublisher.map { $0?.value.showableResolved }.eraseToAnyPublisher()
    }

    var isValidatingDestination: AnyPublisher<Bool, Never> {
        _isValidatingDestination.eraseToAnyPublisher()
    }

    var canEmbedAdditionalField: AnyPublisher<Bool, Never> {
        _canEmbedAdditionalField.eraseToAnyPublisher()
    }

    var destinationValid: AnyPublisher<Bool, Never> {
        _destinationValid.eraseToAnyPublisher()
    }

    var allFieldsIsValid: AnyPublisher<Bool, Never> {
        Publishers
            .CombineLatest(_destinationValid, _additionalFieldValid)
            .map { $0 && $1 }
            .eraseToAnyPublisher()
    }

    var destinationError: AnyPublisher<String?, Never> {
        _destinationError.map { $0?.localizedDescription }.eraseToAnyPublisher()
    }

    var destinationAdditionalFieldError: AnyPublisher<String?, Never> {
        _destinationAdditionalFieldError.map { $0?.localizedDescription }.eraseToAnyPublisher()
    }

    func shouldResolve(address: String) -> Bool {
        guard let addressResolver = dependenciesBuilder.addressResolver else { return false }
        return addressResolver.requiresResolution(address: address)
    }

    func update(destination address: String, source: Analytics.DestinationAddressSource) async {
        let validator = dependenciesBuilder.validator
        _canEmbedAdditionalField.send(validator.canEmbedAdditionalField(into: address))

        guard !address.isEmpty else {
            update(destination: .success(.none), source: source)
            return
        }

        if let validationError = validate(destination: address) {
            update(destination: .failure(validationError), source: source)
            return
        }

        guard let addressResolver = dependenciesBuilder.addressResolver,
              addressResolver.requiresResolution(address: address) else {
            update(destination: .success(.init(value: .plain(address), source: source)), source: source)
            return
        }

        defer { _isValidatingDestination.send(false) }
        _isValidatingDestination.send(true)

        do {
            let result = try await addressResolver.resolve(address)
            let resolvedDestination = SendDestination(
                value: .resolved(address: address, resolved: result.resolved, memoRequired: result.requiresDestinationTag),
                source: source
            )
            update(destination: .success(resolvedDestination), source: source)
        } catch is CancellationError {
            // Do nothing
        } catch let error as SendAddressServiceError {
            update(destination: .failure(error), source: source)
        } catch {
            AppLogger.error("Resolving address error: ", error: error)
            update(destination: .failure(SendAddressServiceError.invalidAddress), source: source)
        }
    }

    func validate(destination address: String) -> Error? {
        do {
            try dependenciesBuilder.validator.validate(destination: address)
            return nil
        } catch {
            return error
        }
    }

    func update(additionalField value: String) {
        guard let type = dependenciesBuilder.additionalFieldType else {
            saver.update(additionalField: .notSupported)
            _additionalFieldValid.send(true)
            return
        }

        guard !value.isEmpty else {
            saver.update(additionalField: .empty(type: type))
            applyMemoValidationIfEnabled()
            return
        }

        do {
            let type = try proceed(additionalField: value)
            saver.update(additionalField: type)
            _destinationAdditionalFieldError.send(nil)
            _additionalFieldValid.send(true)
        } catch {
            _destinationAdditionalFieldError.send(error)
            saver.update(additionalField: .empty(type: type))
            _additionalFieldValid.send(false)
        }
    }

    func preloadTransactionHistoryIfNeeded() {
        dependenciesBuilder.transactionHistoryProvider.preloadTransactionHistoryIfNeeded()
    }
}

private extension CommonSendDestinationInteractor {
    enum Constants {
        static let numberOfRecentTransactions = 10
        static let emptyString = ""
    }
}
