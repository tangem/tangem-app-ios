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

    func willResolve(address: String) -> Bool

    func update(destination: String, source: Analytics.DestinationAddressSource)
    func update(additionalField: String)

    func preloadTransactionsHistoryIfNeeded()

    var ignoreDestinationClear: AnyPublisher<Bool, Never> { get }
    func setIgnoreDestinationClear(_ ignore: Bool)
}

class CommonSendDestinationInteractor {
    private weak var input: SendDestinationInput?
    private weak var receiveTokenInput: SendReceiveTokenInput?

    private var saver: SendDestinationInteractorSaver
    private var dependenciesBuilder: SendDestinationInteractorDependenciesProvider

    private let _isValidatingDestination: CurrentValueSubject<Bool, Never> = .init(false)
    private let _canEmbedAdditionalField: CurrentValueSubject<Bool, Never> = .init(true)

    private let _destinationValid: CurrentValueSubject<Bool, Never> = .init(false)
    private let _destinationError: CurrentValueSubject<Error?, Never> = .init(nil)

    private let _additionalFieldValid: CurrentValueSubject<Bool, Never> = .init(true)
    private let _destinationAdditionalFieldError: CurrentValueSubject<Error?, Never> = .init(nil)

    private let _suggestedWallets: CurrentValueSubject<[SendDestinationSuggestedWallet], Never> = .init([])
    private let _suggestedDestination: CurrentValueSubject<[SendDestinationSuggestedTransactionRecord], Never> = .init([])

    private let _ignoreDestinationClear: CurrentValueSubject<Bool, Never> = .init(false)

    private var updatingTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        input: SendDestinationInput,
        receiveTokenInput: SendReceiveTokenInput,
        saver: SendDestinationInteractorSaver,
        dependenciesBuilder: SendDestinationInteractorDependenciesProvider
    ) {
        self.input = input
        self.receiveTokenInput = receiveTokenInput
        self.saver = saver
        self.dependenciesBuilder = dependenciesBuilder

        bind()
    }

    private func bind() {
        receiveTokenInput?.receiveTokenPublisher
            .receiveOnMain()
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

    private func resolveIfPossible(address: String, source: Analytics.DestinationAddressSource) async throws -> SendDestination {
        guard let addressResolver = dependenciesBuilder.addressResolver else {
            return .init(value: .plain(address), source: source)
        }

        defer { _isValidatingDestination.send(false) }
        _isValidatingDestination.send(true)

        let resolved = try await addressResolver.resolve(address)
        return .init(value: .resolved(address: address, resolved: resolved), source: source)
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
            .map { $0.tokenItem }
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

    func willResolve(address: String) -> Bool {
        guard let addressResolver = dependenciesBuilder.addressResolver else { return false }
        return addressResolver.isNeedToResolve(address: address)
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
                let resolved = try await $0.resolveIfPossible(address: address, source: source)
                $0.update(destination: .success(resolved), source: source)
            } catch is CancellationError {
                // Do nothing
            } catch let error as SendAddressServiceError {
                $0.update(destination: .failure(error), source: source)
            } catch {
                AppLogger.error("Resolving address error: ", error: error)
                $0.update(destination: .failure(SendAddressServiceError.invalidAddress), source: source)
            }
        }
    }

    func update(additionalField value: String) {
        guard let type = dependenciesBuilder.additionalFieldType else {
            assertionFailure("This method don't have to be called if additionalFieldType is nil")
            saver.update(additionalField: .notSupported)
            _additionalFieldValid.send(true)
            return
        }

        guard !value.isEmpty else {
            saver.update(additionalField: .empty(type: type))
            _destinationAdditionalFieldError.send(nil)
            _additionalFieldValid.send(true)
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

    func preloadTransactionsHistoryIfNeeded() {
        dependenciesBuilder.transactionHistoryProvider.preloadTransactionsHistoryIfNeeded()
    }

    var ignoreDestinationClear: AnyPublisher<Bool, Never> {
        _ignoreDestinationClear.eraseToAnyPublisher()
    }

    func setIgnoreDestinationClear(_ ignore: Bool) {
        _ignoreDestinationClear.send(ignore)
    }
}

private extension CommonSendDestinationInteractor {
    enum Constants {
        static let numberOfRecentTransactions = 10
        static let emptyString = ""
    }
}
