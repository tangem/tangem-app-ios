//
//  OnrampAmountViewModel.swift
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

class OnrampAmountViewModel: ObservableObject {
    @Published var fiatItem: FiatItem?
    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextFieldViewModel
    @Published var error: String?
    @Published var currentFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions?

    // MARK: - Dependencies

    weak var router: OnrampSummaryRoutable?

    private let tokenItem: TokenItem
    private let interactor: OnrampSummaryInteractor
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory = .init()
    private let formatter: BalanceFormatter

    private var bag: Set<AnyCancellable> = []

    init(
        tokenItem: TokenItem,
        initialAmount: Decimal?,
        interactor: OnrampSummaryInteractor
    ) {
        self.tokenItem = tokenItem
        self.interactor = interactor

        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: 2)
        formatter = BalanceFormatter()

        decimalNumberTextFieldViewModel.update(value: initialAmount)
        bind()
    }

    func onChangeCurrencyTap() {
        router?.openOnrampCurrencySelector()
    }
}

// MARK: - Private

private extension OnrampAmountViewModel {
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
        interactor.userDidChangeFiat(amount: amount)
    }

    func updateBottomInfoText(bottomInfo: LoadingResult<Decimal, OnrampSummaryInteractorBottomInfoError>?) {
        // We show only error as a bottom info text
        switch bottomInfo {
        case .none, .loading, .success:
            error = nil
        case .failure(.noAvailableProviders):
            error = Localization.onrampNoAvailableProviders
        case .failure(.tooSmallAmount(let minAmount)):
            error = Localization.onrampMinAmountRestriction(minAmount)
        case .failure(.tooBigAmount(let maxAmount)):
            error = Localization.onrampMaxAmountRestriction(maxAmount)
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
