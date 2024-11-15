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

    private let _currency: CurrentValueSubject<LoadingValue<OnrampFiatCurrency>, Never>
    private let _amount: CurrentValueSubject<SendAmount?, Never> = .init(.none)
    private let _selectedOnrampProvider: CurrentValueSubject<LoadingValue<OnrampProvider>?, Never> = .init(.none)
    private let _selectedOnrampPaymentMethod: CurrentValueSubject<OnrampPaymentMethod?, Never>
    private let _onrampProviders: CurrentValueSubject<LoadingValue<[OnrampProvider]>?, Never> = .init(.none)
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
            onrampRepository.preferenceCurrency.map { .loaded($0) } ?? .loading
        )

        _selectedOnrampPaymentMethod = .init(onrampRepository.preferencePaymentMethod)

        bind()
        initiatePaymentMethodDefinitionIfNeeded()
    }
}

// MARK: - Bind

private extension OnrampModel {
    func bind() {
        _amount
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { model, amount in
                model.updateQuotes(amount: amount?.fiat)
            }
            .store(in: &bag)

        // Handle the settings changes
        onrampRepository
            .preferenceCurrencyPublisher
            .removeDuplicates()
            .sink { [weak self] currency in
                self?.preferenceDidChange(currency: currency)
            }
            .store(in: &bag)

        _selectedOnrampPaymentMethod
            .removeDuplicates()
            .sink { [weak self] paymentMethod in
                self?.onrampRepository.updatePreference(paymentMethod: paymentMethod)
            }
            .store(in: &bag)
    }

    func updateProviders(country: OnrampCountry, currency: OnrampFiatCurrency) async throws {
        let request = makeOnrampPairRequestItem(country: country, currency: currency)
        try await onrampManager.setupProviders(request: request)

        await _onrampProviders.send(.loaded(onrampManager.providers))
    }

    func updateQuotes(amount: Decimal?) {
        mainTask {
            guard let amount else {
                $0._selectedOnrampProvider.send(.none)
                // Clear onrampManager
                try await $0.onrampManager.setupQuotes(amount: nil)
                return
            }

            $0._selectedOnrampProvider.send(.loading)

            try await $0.onrampManager.setupQuotes(amount: amount)

            await $0._onrampProviders.send(.loaded($0.onrampManager.providers))
            if let selectedProvider = await $0.onrampManager.selectedProvider {
                $0._selectedOnrampProvider.send(.loaded(selectedProvider))
            }
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
        _currency.send(.loaded(currency))

        mainTask {
            try await $0.updateProviders(country: country, currency: currency)
        }
    }

    func initiateCountryDefinition() async {
        do {
            let country = try await onrampManager.initialSetupCountry()

            // Update amount UI
            _currency.send(.loaded(country.currency))

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

    func initiatePaymentMethodDefinitionIfNeeded() {
        guard _selectedOnrampPaymentMethod.value == nil else {
            return
        }

        TangemFoundation.runTask(in: self) {
            let paymentMethod = try await $0.onrampManager.initialSetupPaymentMethod()
            $0.onrampRepository.updatePreference(paymentMethod: paymentMethod)

            // Update UI
            $0._selectedOnrampPaymentMethod.send(paymentMethod)
        }
    }
}

// MARK: - Helpers

private extension OnrampModel {
    func makeOnrampPairRequestItem(country: OnrampCountry, currency: OnrampFiatCurrency) -> OnrampPairRequestItem {
        OnrampPairRequestItem(fiatCurrency: currency, country: country, destination: walletModel)
    }

    func mainTask(code: @escaping (OnrampModel) async throws -> Void) {
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
    var fiatCurrency: LoadingValue<OnrampFiatCurrency> {
        _currency.value
    }

    var fiatCurrencyPublisher: AnyPublisher<LoadingValue<OnrampFiatCurrency>, Never> {
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

    var selectedOnrampProviderPublisher: AnyPublisher<LoadingValue<OnrampProvider>?, Never> {
        _selectedOnrampProvider.eraseToAnyPublisher()
    }

    var onrampProvidersPublisher: AnyPublisher<LoadingValue<[OnrampProvider]>, Never> {
        _onrampProviders.compactMap { $0 }.eraseToAnyPublisher()
    }
}

// MARK: - OnrampProvidersOutput

extension OnrampModel: OnrampProvidersOutput {
    func userDidSelect(provider: OnrampProvider) {
        _selectedOnrampProvider.send(.loaded(provider))
    }
}

// MARK: - OnrampPaymentMethodsInput

extension OnrampModel: OnrampPaymentMethodsInput {
    var selectedOnrampPaymentMethod: OnrampPaymentMethod? {
        _selectedOnrampPaymentMethod.value
    }

    var selectedOnrampPaymentMethodPublisher: AnyPublisher<OnrampPaymentMethod?, Never> {
        _selectedOnrampPaymentMethod.eraseToAnyPublisher()
    }
}

// MARK: - OnrampPaymentMethodsOutput

extension OnrampModel: OnrampPaymentMethodsOutput {
    func userDidSelect(paymentMethod: OnrampPaymentMethod) {
        _selectedOnrampPaymentMethod.send(paymentMethod)
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
            .compactMap { $0?.value?.manager.state.isReadyToBuy }
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
        _isLoading.eraseToAnyPublisher()
    }
}

// MARK: - SendBaseOutput

extension OnrampModel: SendBaseOutput {
    func performAction() async throws -> TransactionDispatcherResult {
        assertionFailure("OnrampModel doesn't support the send transaction action")
        throw TransactionDispatcherResult.Error.actionNotSupported
    }
}

enum OnrampModelError: String, LocalizedError {
    case countryNotFound
    case currencyNotFound

    var errorDescription: String? { rawValue }
}
