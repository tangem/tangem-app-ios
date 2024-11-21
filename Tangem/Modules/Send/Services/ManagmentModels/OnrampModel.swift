//
//  OnrampModel.swift
//  TangemApp
//
//  Created by Sergey Balashov on 15.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import Combine
import TangemFoundation

protocol OnrampModelRoutable: AnyObject {
    func openOnrampCountryBottomSheet(country: OnrampCountry)
    func openOnrampCountrySelectorView()
    func openWebView(url: URL, success: @escaping () -> Void)
    func openFinishStep()
}

class OnrampModel {
    // MARK: - Data

    private let _currency: CurrentValueSubject<LoadingResult<OnrampFiatCurrency, Never>, Never>
    private let _amount: CurrentValueSubject<SendAmount?, Never> = .init(.none)
    private let _onrampProviders: CurrentValueSubject<LoadingResult<ProvidersList, Error>?, Never> = .init(.none)
    private let _selectedOnrampProvider: CurrentValueSubject<LoadingResult<OnrampProvider, Never>?, Never> = .init(.none)
    private let _isLoading: CurrentValueSubject<Bool, Never> = .init(false)
    private let _transactionTime = PassthroughSubject<Date?, Never>()

    // MARK: - Dependencies

    weak var router: OnrampModelRoutable?
    weak var alertPresenter: SendViewAlertPresenter?

    // MARK: - Private injections

    private let walletModel: WalletModel
    private let onrampManager: OnrampManager
    private let onrampRepository: OnrampRepository

    private var task: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        walletModel: WalletModel,
        onrampManager: OnrampManager,
        onrampRepository: OnrampRepository
    ) {
        self.walletModel = walletModel
        self.onrampManager = onrampManager
        self.onrampRepository = onrampRepository

        _currency = .init(
            onrampRepository.preferenceCurrency.map { .success($0) } ?? .loading
        )

        bind()
    }
}

// MARK: - Bind

private extension OnrampModel {
    func bind() {
        _amount
            .dropFirst()
            .print("amount ->>")
            .withWeakCaptureOf(self)
            .sink { model, amount in
                model.amountDidChange(amount: amount?.fiat)
            }
            .store(in: &bag)

        // Handle the settings changes
        onrampRepository
            .preferenceCurrencyPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { model, currency in
                model.preferenceDidChange(currency: currency)
            }
            .store(in: &bag)
    }

    // MARK: - Providers list

    func updateProviders() async {
        guard let country = onrampRepository.preferenceCountry,
              let currency = onrampRepository.preferenceCurrency else {
            return
        }

        await updateProviders(country: country, currency: currency)
    }

    func updateProviders(country: OnrampCountry, currency: OnrampFiatCurrency) async {
        do {
            _onrampProviders.send(.loading)
            let request = makeOnrampPairRequestItem(country: country, currency: currency)
            let providers = try await onrampManager.setupProviders(request: request)
            try Task.checkCancellation()
            _onrampProviders.send(.success(providers))

            try Task.checkCancellation()
            try await updateQuotes()
        } catch {
            _onrampProviders.send(.failure(error))
        }
    }

    func providersList() throws -> ProvidersList {
        guard let providers = _onrampProviders.value else {
            throw OnrampManagerError.providersIsEmpty
        }

        return try providers.get()
    }

    // MARK: - Quotes

    func amountDidChange(amount: Decimal?) {
        switch _onrampProviders.value {
        case .success(let list) where list.hasProviders():
            mainTask {
                try await $0.updateQuotes(amount: amount)
            }
        case .none, .loading, .success, .failure:
            // TODO: What we do when providers in the one of state above?
            return
        }
    }

    func updateQuotes() async throws {
        try await updateQuotes(amount: _amount.value?.fiat)
    }

    func updateQuotes(amount: Decimal?) async throws {
        guard let amount else {
            try await clearOnrampManager()
            return
        }

        try await updateOnrampManager(amount: amount)
    }

    func clearOnrampManager() async throws {
        let provider = try await onrampManager.setupQuotes(in: providersList(), amount: .none)
        try Task.checkCancellation()
        _selectedOnrampProvider.send(.success(provider))
    }

    func updateOnrampManager(amount: Decimal?) async throws {
        _selectedOnrampProvider.send(.loading)
        let provider = try await onrampManager.setupQuotes(in: providersList(), amount: amount)
        try Task.checkCancellation()
        _selectedOnrampProvider.send(.success(provider))
    }

    // MARK: - Payment method

    func updatePaymentMethod(method: OnrampPaymentMethod) {
        mainTask {
            let provider = try await $0.onrampManager.suggestProvider(in: $0.providersList(), paymentMethod: method)
            try Task.checkCancellation()
            $0._selectedOnrampProvider.send(.success(provider))
        }
    }
}

// MARK: - Preference bindings

private extension OnrampModel {
    func preferenceDidChange(currency: OnrampFiatCurrency?) {
        guard let country = onrampRepository.preferenceCountry, let currency else {
            TangemFoundation.runTask(in: self) {
                await $0.initiateCountryDefinition()
            }
            return
        }

        // Update amount UI
        _currency.send(.success(currency))
        mainTask {
            await $0.updateProviders(country: country, currency: currency)
        }
    }

    func initiateCountryDefinition() async {
        do {
            let country = try await onrampManager.initialSetupCountry()

            // Update amount UI
            _currency.send(.success(country.currency))

            // We have to show confirmation bottom sheet
            await runOnMain {
                router?.openOnrampCountryBottomSheet(country: country)
            }
        } catch {
            await runOnMain {
                alertPresenter?.showAlert(error.alertBinder)
            }
        }
    }
}

// MARK: - Helpers

private extension OnrampModel {
    func makeOnrampPairRequestItem(country: OnrampCountry, currency: OnrampFiatCurrency) -> OnrampPairRequestItem {
        OnrampPairRequestItem(fiatCurrency: currency, country: country, destination: walletModel)
    }

    func mainTask(code: @escaping (OnrampModel) async throws -> Void) {
        task?.cancel()
        task = TangemFoundation.runTask(in: self) { model in
            do {
                try await code(model)
            } catch _ as CancellationError {
                // Do nothing
            } catch {
                await runOnMain {
                    model.alertPresenter?.showAlert(error.alertBinder)
                }
            }
        }
    }
}

// MARK: - OnrampAmountInput

extension OnrampModel: OnrampAmountInput {
    var fiatCurrency: LoadingResult<OnrampFiatCurrency, Never> {
        _currency.value
    }

    var fiatCurrencyPublisher: AnyPublisher<LoadingResult<OnrampFiatCurrency, Never>, Never> {
        _currency.eraseToAnyPublisher()
    }
}

// MARK: - OnrampAmountOutput

extension OnrampModel: OnrampAmountOutput {
    func amountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
    }
}

// MARK: - OnrampProvidersInput

extension OnrampModel: OnrampProvidersInput {
    var selectedOnrampProvider: OnrampProvider? {
        _selectedOnrampProvider.value?.value
    }

    var selectedOnrampProviderPublisher: AnyPublisher<LoadingResult<OnrampProvider, Never>?, Never> {
        _selectedOnrampProvider.eraseToAnyPublisher()
    }

    var onrampProvidersPublisher: AnyPublisher<LoadingResult<ProvidersList, Error>?, Never> {
        _onrampProviders.eraseToAnyPublisher()
    }
}

// MARK: - OnrampProvidersOutput

extension OnrampModel: OnrampProvidersOutput {
    func userDidSelect(provider: OnrampProvider) {
        _selectedOnrampProvider.send(.success(provider))
    }
}

// MARK: - OnrampPaymentMethodsInput

extension OnrampModel: OnrampPaymentMethodsInput {
    var selectedPaymentMethod: OnrampPaymentMethod? {
        _selectedOnrampProvider.value?.value?.paymentMethod
    }

    var selectedPaymentMethodPublisher: AnyPublisher<OnrampPaymentMethod?, Never> {
        _selectedOnrampProvider.map { $0?.value?.paymentMethod }.eraseToAnyPublisher()
    }

    var paymentMethodsPublisher: AnyPublisher<[OnrampPaymentMethod], Never> {
        _onrampProviders.compactMap {
            $0?.value?.filter { $0.hasProviders() }.map(\.paymentMethod)
        }.eraseToAnyPublisher()
    }
}

// MARK: - OnrampPaymentMethodsOutput

extension OnrampModel: OnrampPaymentMethodsOutput {
    func userDidSelect(paymentMethod: OnrampPaymentMethod) {
        updatePaymentMethod(method: paymentMethod)
    }
}

// MARK: - OnrampRedirectingInput

extension OnrampModel: OnrampRedirectingInput {}

// MARK: - OnrampRedirectingOutput

extension OnrampModel: OnrampRedirectingOutput {
    func redirectDataDidLoad(data: OnrampRedirectData) {
        DispatchQueue.main.async {
            self.router?.openWebView(url: data.widgetUrl) { [weak self] in
                self?._transactionTime.send(Date())
                self?.router?.openFinishStep()
            }
        }
    }
}

// MARK: - OnrampInput

extension OnrampModel: OnrampInput {
    var isValidToRedirectPublisher: AnyPublisher<Bool, Never> {
        _selectedOnrampProvider
            .map { $0?.value?.isReadyToBuy ?? false }
            .eraseToAnyPublisher()
    }
}

// MARK: - OnrampOutput

extension OnrampModel: OnrampOutput {}

// MARK: - SendAmountInput

extension OnrampModel: SendAmountInput {
    var amount: SendAmount? { _amount.value }

    var amountPublisher: AnyPublisher<SendAmount?, Never> {
        _amount.eraseToAnyPublisher()
    }
}

// MARK: - SendFinishInput

extension OnrampModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput

extension OnrampModel: SendBaseInput {
    var actionInProcessing: AnyPublisher<Bool, Never> {
        Publishers
            .Merge3(
                _isLoading,
                _currency.map { $0.isLoading },
                _onrampProviders.compactMap { $0?.isLoading }
            )
            .eraseToAnyPublisher()
    }
}

// MARK: - SendBaseOutput

extension OnrampModel: SendBaseOutput {
    func performAction() async throws -> TransactionDispatcherResult {
        assertionFailure("OnrampModel doesn't support the send transaction action")
        throw TransactionDispatcherResult.Error.actionNotSupported
    }
}

// MARK: - OnrampNotificationManagerInput

extension OnrampModel: OnrampNotificationManagerInput {
    var errorPublisher: AnyPublisher<Error?, Never> {
        let onrampProvidersErrorPublisher = _onrampProviders
            .compactMap { $0 }
            .filter { !$0.isLoading }
            .map { $0.error }

        let selectedOnrampProviderErrorPublisher = _selectedOnrampProvider
            // Here we clear error on `loading` state
            // Because we have the LoadingView
            .map { $0?.value?.error }

        return Publishers.Merge(
            onrampProvidersErrorPublisher,
            selectedOnrampProviderErrorPublisher
        )
        .eraseToAnyPublisher()
    }

    func refreshError() {
        if case .failure = _currency.value {
            TangemFoundation.runTask(in: self) {
                await $0.initiateCountryDefinition()
            }
        }

        if case .failure = _onrampProviders.value {
            mainTask {
                await $0.updateProviders()
            }
        }

        if case .failed = _selectedOnrampProvider.value?.value?.state {
            mainTask {
                try await $0.updateQuotes()
            }
        }
    }
}

// MARK: - NotificationTapDelegate

extension OnrampModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refresh:
            refreshError()
        default:
            assertionFailure("Action not supported: \(action)")
        }
    }
}

private extension OnrampModel {
    struct ProviderState {
        let list: ProvidersList
        let selected: OnrampProvider

        enum LoadingError {
            case pairs(Error)
            case quotes(Error)
        }
    }
}
