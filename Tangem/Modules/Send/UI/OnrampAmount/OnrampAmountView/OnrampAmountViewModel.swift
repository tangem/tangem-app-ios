//
//  OnrampAmountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation

class OnrampAmountViewModel: ObservableObject {
    @Published var fiatIconURL: URL?
    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var alternativeAmount: String?
    @Published var bottomInfoText: SendAmountViewModel.BottomInfoTextType?
    @Published var currentFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions?
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let interactor: OnrampAmountInteractor
    private weak var coordinator: OnrampAmountRoutable?
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory = .init()

    private var updatingAmountTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        tokenItem: TokenItem,
        interactor: OnrampAmountInteractor,
        coordinator: OnrampAmountRoutable
    ) {
        self.interactor = interactor
        self.tokenItem = tokenItem
        self.coordinator = coordinator

        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: 2)

        bind()
    }

    func onChangeCurrencyTap() {
        coordinator?.openOnrampCurrencySelector()
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
            .valuePublisher
            .debounce(for: 1, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, value in
                viewModel.textFieldValueDidChanged(amount: value)
            }
            .store(in: &bag)

        interactor
            .errorPublisher
            .map { $0.map { .error($0) } }
            .receive(on: DispatchQueue.main)
            .assign(to: \.bottomInfoText, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func update(currency: OnrampFiatCurrency?) {
        switch currency {
        case .none:
            // Equal to loading state
            fiatIconURL = nil
            isLoading = true

        case .some(let currency):
            fiatIconURL = currency.identity.image
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: currency.precision)
            currentFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions(
                fiatCurrencyCode: currency.identity.code
            )
            updateAlternativeAmount(amount: .none)
            isLoading = false
        }
    }

    func textFieldValueDidChanged(amount: Decimal?) {
        updatingAmountTask?.cancel()
        updatingAmountTask = TangemFoundation.runTask(in: self) { viewModel in
            let amount = await viewModel.interactor.update(amount: amount)

            await runOnMain {
                viewModel.updateAlternativeAmount(amount: amount)
            }
        }
    }

    func updateAlternativeAmount(amount: SendAmount?) {
        let amount = amount ?? SendAmount(type: .alternative(fiat: nil, crypto: 0))
        alternativeAmount = amount.formatAlternative(
            currencySymbol: tokenItem.currencySymbol,
            trimFractions: false,
            decimalCount: tokenItem.decimalCount
        )
    }
}
