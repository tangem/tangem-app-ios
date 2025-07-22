//
//  CommonSendNewDestinationInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import BlockchainSdk

protocol SendNewDestinationInteractor {
    var tokenItemPublisher: AnyPublisher<TokenItem, Never> { get }
    var suggestedWalletsPublisher: AnyPublisher<[SendSuggestedDestinationWallet], Never> { get }
    var transactionHistoryPublisher: AnyPublisher<[SendSuggestedDestinationTransactionRecord], Never> { get }

    var isValidatingDestination: AnyPublisher<Bool, Never> { get }
    var canEmbedAdditionalField: AnyPublisher<Bool, Never> { get }
    var destinationValid: AnyPublisher<Bool, Never> { get }
    var allFieldsIsValid: AnyPublisher<Bool, Never> { get }
    var destinationError: AnyPublisher<String?, Never> { get }
    var destinationAdditionalFieldError: AnyPublisher<String?, Never> { get }

    func update(destination: String, source: Analytics.DestinationAddressSource)
    func update(additionalField: String)
    func preloadTransactionsHistoryIfNeeded()

    func saveChanges()
}

class CommonSendNewDestinationInteractor {
    private weak var input: SendDestinationInput?
    private weak var output: SendDestinationOutput?
    private weak var receiveTokenInput: SendReceiveTokenInput?

    private var dependenciesBuilder: SendNewDestinationInteractorDependenciesProvider

    private let _isValidatingDestination: CurrentValueSubject<Bool, Never> = .init(false)
    private let _canEmbedAdditionalField: CurrentValueSubject<Bool, Never> = .init(true)

    private let _destinationValid: CurrentValueSubject<Bool, Never> = .init(false)
    private let _destinationError: CurrentValueSubject<Error?, Never> = .init(nil)

    private let _additionalFieldValid: CurrentValueSubject<Bool, Never> = .init(true)
    private let _destinationAdditionalFieldError: CurrentValueSubject<Error?, Never> = .init(nil)

    private let _suggestedWallets: CurrentValueSubject<[SendSuggestedDestinationWallet], Never> = .init([])
    private let _suggestedDestination: CurrentValueSubject<[SendSuggestedDestinationTransactionRecord], Never> = .init([])

    private let _cachedDestination: CurrentValueSubject<SendAddress?, Never>
    private let _cachedAdditionalField: CurrentValueSubject<SendDestinationAdditionalField, Never>

    private var updatingTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        input: SendDestinationInput,
        output: SendDestinationOutput,
        receiveTokenInput: SendReceiveTokenInput,
        dependenciesBuilder: SendNewDestinationInteractorDependenciesProvider
    ) {
        self.input = input
        self.output = output
        self.receiveTokenInput = receiveTokenInput
        self.dependenciesBuilder = dependenciesBuilder

        _cachedDestination = .init(input.destination)
        _cachedAdditionalField = .init(input.destinationAdditionalField)

        bind()
    }

    private func bind() {
        receiveTokenInput?.receiveTokenPublisher
            .receiveOnGlobal()
            .withWeakCaptureOf(self)
            .sink { $0.updateDependencies(receivedTokenType: $1) }
            .store(in: &bag)
    }

    private func updateDependencies(receivedTokenType: SendReceiveTokenType) {
        dependenciesBuilder.update(receivedTokenType: receivedTokenType)

        _suggestedWallets.send(dependenciesBuilder.suggestedWallets)
        dependenciesBuilder.transactionHistoryProvider
            .transactionHistoryPublisher
            .assign(to: \._suggestedDestination.value, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func update(destination result: Result<String?, Error>, source: Analytics.DestinationAddressSource) {
        switch result {
        case .success(.none), .success(.empty):
            _destinationValid.send(false)
            _destinationError.send(.none)
            _cachedDestination.send(.none)

        case .success(.some(let address)):
            assert(!address.isEmpty, "Had to fall in case above")

            _destinationValid.send(true)
            _destinationError.send(.none)
            dependenciesBuilder.analyticsLogger.logSendAddressEntered(isAddressValid: true, source: source)
            _cachedDestination.send(.init(value: address, source: source))

        case .failure(let error):
            _destinationValid.send(false)
            _destinationError.send(error)
            dependenciesBuilder.analyticsLogger.logSendAddressEntered(isAddressValid: false, source: source)
            _cachedDestination.send(.none)
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

    private func resolveIfPossible(address: String) async throws -> String {
        guard let addressResolver = dependenciesBuilder.addressResolver else {
            return address
        }

        defer { _isValidatingDestination.send(false) }

        _isValidatingDestination.send(true)
        let resolved = try await addressResolver.resolve(address)
        return resolved
    }
}

// MARK: - SendDestinationInteractor

extension CommonSendNewDestinationInteractor: SendNewDestinationInteractor {
    var hasError: Bool {
        _destinationError.value != nil || _destinationAdditionalFieldError.value != nil
    }

    var tokenItemPublisher: AnyPublisher<TokenItem, Never> {
        guard let receiveTokenInput else {
            return Empty().eraseToAnyPublisher()
        }

        return receiveTokenInput
            .receiveTokenPublisher
            .map { $0.tokenItem }
            .eraseToAnyPublisher()
    }

    var transactionHistoryPublisher: AnyPublisher<[SendSuggestedDestinationTransactionRecord], Never> {
        _suggestedDestination.eraseToAnyPublisher()
    }

    var suggestedWalletsPublisher: AnyPublisher<[SendSuggestedDestinationWallet], Never> {
        _suggestedWallets.eraseToAnyPublisher()
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

    func update(destination address: String, source: Analytics.DestinationAddressSource) {
        let validator = dependenciesBuilder.validator
        _canEmbedAdditionalField.send(validator.canEmbedAdditionalField(into: address))

        guard !address.isEmpty else {
            update(destination: .success(.none), source: source)
            return
        }

        updatingTask?.cancel()
        updatingTask = runTask(in: self) {
            do {
                try validator.validate(destination: address)
                let resolved = try await $0.resolveIfPossible(address: address)
                $0.update(destination: .success(resolved), source: source)
            } catch is CancellationError {
                // Do nothing
            } catch {
                $0.update(destination: .failure(error), source: source)
            }
        }
    }

    func update(additionalField value: String) {
        guard let type = dependenciesBuilder.additionalFieldType else {
            assertionFailure("This method don't have to be called if additionalFieldType is nil")
            _cachedAdditionalField.send(.notSupported)
            _additionalFieldValid.send(true)
            return
        }

        guard !value.isEmpty else {
            output?.destinationAdditionalParametersDidChanged(.empty(type: type))
            _destinationAdditionalFieldError.send(nil)
            _additionalFieldValid.send(true)
            return
        }

        do {
            let type = try proceed(additionalField: value)
            _cachedAdditionalField.send(type)
            _destinationAdditionalFieldError.send(nil)
            _additionalFieldValid.send(true)
        } catch {
            _destinationAdditionalFieldError.send(error)
            _cachedAdditionalField.send(.empty(type: type))
            _additionalFieldValid.send(false)
        }
    }

    func preloadTransactionsHistoryIfNeeded() {
        dependenciesBuilder.transactionHistoryProvider.preloadTransactionsHistoryIfNeeded()
    }

    func saveChanges() {
        output?.destinationDidChanged(_cachedDestination.value)
        output?.destinationAdditionalParametersDidChanged(_cachedAdditionalField.value)
    }
}

private extension CommonSendDestinationInteractor {
    enum Constants {
        static let numberOfRecentTransactions = 10
        static let emptyString = ""
    }
}
