//
//  NewOnrampAmountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import TangemExpress
import TangemFoundation

class NewOnrampAmountViewModel: ObservableObject {
    @Published var fiatItem: FiatItem?
    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var bottomInfoText: (state: LoadableTextView.State, isError: Bool) = (.initialized, false)
    @Published var currentFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions?

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let interactor: OnrampAmountInteractor
    private weak var coordinator: OnrampAmountRoutable?
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory = .init()
    private let formatter: BalanceFormatter

    private var bag: Set<AnyCancellable> = []

    init(
        tokenItem: TokenItem,
        initialAmount: Decimal?,
        interactor: OnrampAmountInteractor,
        coordinator: OnrampAmountRoutable
    ) {
        self.tokenItem = tokenItem
        self.interactor = interactor
        self.coordinator = coordinator

        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: 2)
        formatter = BalanceFormatter()

        decimalNumberTextFieldViewModel.update(value: initialAmount)
        bind()
    }

    func onChangeCurrencyTap() {
        coordinator?.openOnrampCurrencySelector()
    }
}

// MARK: - Private

private extension NewOnrampAmountViewModel {
    func bind() {
        interactor
            .currencyPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, currency in
                viewModel.update(currency: currency)
            }
            .store(in: &bag)

        decimalNumberTextFieldViewModel
            .debouncedValuePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, value in
                viewModel.textFieldValueDidChanged(amount: value)
            }
            .store(in: &bag)

        interactor
            .bottomInfoPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, bottomInfo in
                viewModel.updateBottomInfoText(bottomInfo: bottomInfo)
            }
            .store(in: &bag)
    }

    func update(currency: OnrampFiatCurrency?) {
        switch currency {
        case .none:
            // Equal to loading state
            fiatItem = nil
            currentFieldOptions = nil

        case .some(let currency):
            fiatItem = .init(
                iconURL: currency.identity.image,
                currencyCode: currency.identity.code,
                fractionDigits: currency.precision
            )
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: currency.precision)
            currentFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions(
                fiatCurrencyCode: currency.identity.code
            )
        }
    }

    func textFieldValueDidChanged(amount: Decimal?) {
        interactor.update(fiat: amount)
    }

    func updateBottomInfoText(bottomInfo: LoadingResult<Decimal, OnrampAmountInteractorBottomInfoError>?) {
        switch bottomInfo {
        case .loading:
            bottomInfoText = (.loading, false)
        case .success(let success):
            bottomInfoText = (format(crypto: success), false)
        case .failure(.noAvailableProviders):
            bottomInfoText = (.loaded(text: Localization.onrampNoAvailableProviders), true)
        case .failure(.tooSmallAmount(let minAmount)):
            bottomInfoText = (.loaded(text: Localization.onrampMinAmountRestriction(minAmount)), true)
        case .failure(.tooBigAmount(let maxAmount)):
            bottomInfoText = (.loaded(text: Localization.onrampMaxAmountRestriction(maxAmount)), true)
        case .none:
            bottomInfoText = (.noData, false)
        }
    }

    func format(crypto: Decimal) -> LoadableTextView.State {
        let formatted = formatter.formatCryptoBalance(crypto, currencyCode: tokenItem.currencySymbol)

        if crypto > 0 {
            return .loaded(text: "\(AppConstants.tildeSign) \(formatted)")
        }

        // Like placeholder
        return .loaded(text: formatted)
    }
}
