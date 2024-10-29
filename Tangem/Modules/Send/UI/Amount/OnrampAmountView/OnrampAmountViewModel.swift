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

class OnrampAmountViewModel: ObservableObject {
    @Published var fiatIconURL: URL?
    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var alternativeAmount: String?
    @Published var bottomInfoText: SendAmountViewModel.BottomInfoTextType?
    @Published var currentFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions?

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let repository: OnrampRepository
    private let interactor: SendAmountInteractor
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory = .init()

    private var bag: Set<AnyCancellable> = []

    init(
        tokenItem: TokenItem,
        repository: OnrampRepository,
        interactor: SendAmountInteractor
    ) {
        self.interactor = interactor
        self.repository = repository
        self.tokenItem = tokenItem

        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: 2)

        bind()
    }
}

// MARK: - Private

private extension OnrampAmountViewModel {
    func bind() {
        repository
            .preferenceDidChangedPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, _ in
                viewModel.repository.savedCountry.map { country in
                    viewModel.fiatIconURL = country.currency.identity.image
                    viewModel.decimalNumberTextFieldViewModel.update(maximumFractionDigits: country.currency.precision)
                    viewModel.currentFieldOptions = viewModel.prefixSuffixOptionsFactory.makeFiatOptions(
                        fiatCurrencyCode: country.currency.identity.code
                    )
                }
            }
            .store(in: &bag)

        decimalNumberTextFieldViewModel
            .valuePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, value in
                viewModel.textFieldValueDidChanged(amount: value)
            }
            .store(in: &bag)

        interactor
            .infoTextPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.bottomInfoText, on: self, ownership: .weak)
            .store(in: &bag)

        interactor
            .externalAmountPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amount in
                viewModel.setExternalAmount(amount?.main)
                viewModel.alternativeAmount = amount?.formatAlternative(
                    currencySymbol: viewModel.tokenItem.currencySymbol,
                    decimalCount: viewModel.tokenItem.decimalCount
                )
            }
            .store(in: &bag)
    }

    func setExternalAmount(_ amount: Decimal?) {
        decimalNumberTextFieldViewModel.update(value: amount)
        textFieldValueDidChanged(amount: amount)
    }

    func textFieldValueDidChanged(amount: Decimal?) {
        let amount = interactor.update(amount: amount)
        alternativeAmount = amount?.formatAlternative(
            currencySymbol: tokenItem.currencySymbol,
            decimalCount: tokenItem.decimalCount
        )
    }
}
