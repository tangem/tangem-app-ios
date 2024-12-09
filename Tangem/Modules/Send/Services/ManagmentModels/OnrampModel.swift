//
//  OnrampModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
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

    private let _currency: CurrentValueSubject<LoadingResult<OnrampFiatCurrency, Error>, Never>
    private let _amount: CurrentValueSubject<Decimal?, Never> = .init(.none)
    private let _onrampProviders: CurrentValueSubject<LoadingResult<ProvidersList, Error>?, Never> = .init(.none)
    private let _selectedOnrampProvider: CurrentValueSubject<LoadingResult<OnrampProvider, Never>?, Never> = .init(.none)
    private let _isLoading: CurrentValueSubject<Bool, Never> = .init(false)
    private let _transactionTime = PassthroughSubject<Date?, Never>()

    // MARK: - Dependencies

    @Injected(\.onrampPendingTransactionsRepository) private var onrampPendingTransactionsRepository: OnrampPendingTransactionRepository
    weak var router: OnrampModelRoutable?
    weak var alertPresenter: SendViewAlertPresenter?

    // MARK: - Private injections

    private let userWalletId: String
    private let walletModel: WalletModel
    private let onrampManager: OnrampManager
    private let onrampDataRepository: OnrampDataRepository
    private let onrampRepository: OnrampRepository

    private var task: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        userWalletId: String,
        walletModel: WalletModel,
        onrampManager: OnrampManager,
        onrampDataRepository: OnrampDataRepository,
        onrampRepository: OnrampRepository
    ) {
        self.userWalletId = userWalletId
        self.walletModel = walletModel
        self.onrampManager = onrampManager
        self.onrampDataRepository = onrampDataRepository
        self.onrampRepository = onrampRepository

        _currency = .init(
            onrampRepository.preferenceCurrency.map { .success($0) } ?? .loading
        )

        bind()
    }

    deinit {
        log("deinit")
    }
}

// MARK: - Bind

private extension OnrampModel {
    func bind() {
        _amount
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { model, amount in
                model.amountDidChange(amount: amount)
            }
            .store(in: &bag)

        // Handle the settings changes
        onrampRepository
            .preferencePublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { model, preference in
                model.preferenceDidChange(country: preference.country, currency: preference.currency)
            }
            .store(in: &bag)

        // Only for analytics
        _selectedOnrampProvider
            .compactMap { $0?.value }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { model, provider in
                switch provider.state {
                case .restriction(.tooSmallAmount):
                    Analytics.log(.onrampErrorMinAmount)
                case .restriction(.tooBigAmount):
                    Analytics.log(.onrampErrorMaxAmount)
                case .failed(let error as ExpressAPIError):
                    Analytics.log(
                        event: .onrampErrors,
                        params: [
                            .token: model.walletModel.tokenItem.currencySymbol,
                            .provider: provider.provider.name,
                            .errorCode: error.errorCode.rawValue.description,
                        ]
                    )
                case .loaded:
                    Analytics.log(
                        event: .onrampProviderCalculated,
                        params: [
                            .token: model.walletModel.tokenItem.currencySymbol,
                            .provider: provider.provider.name,
                            .paymentMethod: provider.paymentMethod.name,
                        ]
                    )
                default:
                    break
                }
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

            // In case when user change country / currency
            // And we have an amount in the filed
            // We'll show loading view like we load /quotes
            // When we load /pairs
            if hasAmount() {
                _selectedOnrampProvider.send(.loading)
            }

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

    func hasAmount() -> Bool {
        _amount.value != nil
    }

    // MARK: - Quotes

    func amountDidChange(amount: Decimal?) {
        switch _onrampProviders.value {
        case .success(let list) where list.hasProviders():
            mainTask {
                try await $0.updateQuotes(amount: amount)
            }
        case .none, .loading, .success, .failure:
            // [REDACTED_TODO_COMMENT]
            return
        }
    }

    func updateQuotes() async throws {
        do {
            try await updateQuotes(amount: _amount.value)
        } catch OnrampManagerError.providersIsEmpty {
            _selectedOnrampProvider.send(.none)
        } catch {
            throw error
        }
    }

    func updateQuotes(amount: Decimal?) async throws {
        guard let amount, amount > 0 else {
            try await clearOnrampManager()
            return
        }

        try await updateOnrampManager(amount: amount)
    }

    func clearOnrampManager() async throws {
        let provider = try await onrampManager.setupQuotes(in: providersList(), amount: .clear)
        try Task.checkCancellation()
        _selectedOnrampProvider.send(.success(provider))
    }

    func updateOnrampManager(amount: Decimal) async throws {
        _selectedOnrampProvider.send(.loading)
        let provider = try await onrampManager.setupQuotes(in: providersList(), amount: .amount(amount))
        try Task.checkCancellation()
        _selectedOnrampProvider.send(.success(provider))

        // Do not start autoupdating for all error cases
        if provider.isSuccessfullyLoaded {
            try await autoupdateTask()
        }
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
    func preferenceDidChange(country: OnrampCountry?, currency: OnrampFiatCurrency?) {
        guard let country, let currency else {
            TangemFoundation.runTask(in: self) {
                await $0.initiateCountryDefinition()
            }
            return
        }

        // Update amount UI
        _currency.send(.success(currency))

        mainTask {
            guard await $0.isCountryAvailable(country: country) else {
                await $0.initiateCountryDefinition()
                return
            }

            await $0.updateProviders(country: country, currency: currency)
        }
    }

    func isCountryAvailable(country: OnrampCountry) async -> Bool {
        do {
            let countries = try await onrampDataRepository.countries()
            let country = countries.first(where: { $0.identity == country.identity })
            let onrampAvailable = country?.onrampAvailable ?? false
            if !onrampAvailable {
                // Clear repo
                onrampRepository.updatePreference(country: nil, currency: nil)
            }
            return onrampAvailable
        } catch {
            _currency.send(.failure(error))
            return false
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
            _currency.send(.failure(error))
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

    func autoupdateTask() async throws {
        guard _selectedOnrampProvider.value?.value?.isSuccessfullyLoaded == true else {
            log("Selected provider has an error. Do not start autoupdate")
            return
        }

        try Task.checkCancellation()

        log("Start timer to autoupdate")
        try await Task.sleep(seconds: 10)

        try Task.checkCancellation()
        // we don't update the selected provider
        log("Call autoupdate")
        let providerForReselect = try await onrampManager.setupQuotes(in: providersList(), amount: .same)

        // Check after reloading
        guard _selectedOnrampProvider.value?.value?.isSuccessfullyLoaded == true else {
            log("Selected provider has a error. Will update to \(providerForReselect)")
            _selectedOnrampProvider.send(.success(providerForReselect))
            try await autoupdateTask()
            return
        }

        // Push the same provider to notify all listeners
        _selectedOnrampProvider.resend()
        _onrampProviders.resend()

        // Restart task
        try await autoupdateTask()
    }

    func log(_ message: String) {
        AppLog.shared.debug("[\(TangemFoundation.objectDescription(self))] \(message)")
    }
}

// MARK: - OnrampAmountInput

extension OnrampModel: OnrampAmountInput {
    var amountPublisher: AnyPublisher<Decimal?, Never> {
        _amount.eraseToAnyPublisher()
    }

    var fiatCurrency: OnrampFiatCurrency? {
        _currency.value.value
    }

    var fiatCurrencyPublisher: AnyPublisher<OnrampFiatCurrency?, Never> {
        _currency.map { $0.value }.eraseToAnyPublisher()
    }
}

// MARK: - OnrampAmountOutput

extension OnrampModel: OnrampAmountOutput {
    func amountDidChanged(fiat: Decimal?) {
        _amount.send(fiat)
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
            $0?.value?.filter { $0.hasShowableProviders() }.map(\.paymentMethod)
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
        guard let provider = selectedOnrampProvider else {
            assertionFailure("selectedOnrampProvider is unexpectedly nil")
            return
        }

        let txData = SentOnrampTransactionData(
            txId: data.txId,
            provider: provider.provider,
            destinationTokenItem: walletModel.tokenItem,
            date: Date(),
            fromAmount: data.fromAmount,
            fromCurrencyCode: data.fromCurrencyCode,
            externalTxId: data.externalTxId
        )

        onrampPendingTransactionsRepository
            .onrampTransactionDidSend(txData, userWalletId: userWalletId)

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
            .map { $0?.value?.isSuccessfullyLoaded ?? false }
            .eraseToAnyPublisher()
    }
}

// MARK: - OnrampOutput

extension OnrampModel: OnrampOutput {}

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
            .Merge(_isLoading, _currency.map { $0.isLoading })
            .eraseToAnyPublisher()
    }
}

// MARK: - SendBaseOutput

extension OnrampModel: SendBaseOutput {
    func performAction() async throws -> TransactionDispatcherResult {
        assertionFailure("OnrampModel doesn't support the send transaction action")
        throw TransactionDispatcherResult.Error.actionNotSupported
    }

    func flowDidDisappear() {
        task?.cancel()
    }
}

// MARK: - OnrampNotificationManagerInput

extension OnrampModel: OnrampNotificationManagerInput {
    var errorPublisher: AnyPublisher<Error?, Never> {
        let currencyErrorPublisher = _currency
            .filter { !$0.isLoading }
            .map { $0.error }

        let onrampProvidersErrorPublisher = _onrampProviders
            .compactMap { $0 }
            .filter { !$0.isLoading }
            .map { $0.error }

        let selectedOnrampProviderErrorPublisher = _selectedOnrampProvider
            .compactMap { $0 }
            // Here we clear error on `loading` state
            // Because we have the LoadingView
            .map { $0?.value?.error }

        return Publishers.Merge3(
            currencyErrorPublisher,
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
