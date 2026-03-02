//
//  AmountInputFieldModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import struct TangemUI.TokenIconInfo

class AmountInputFieldModel: ObservableObject {
    // MARK: - Published

    @Published var amountType: SendAmountCalculationType = .crypto
    @Published var cryptoTextFieldViewModel: DecimalNumberTextFieldViewModel
    @Published var fiatTextFieldViewModel: DecimalNumberTextFieldViewModel
    @Published var cryptoTextFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published var fiatTextFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published var alternativeAmount: String
    @Published var cryptoIconURL: URL?
    @Published var possibleToConvertToFiat: Bool
    @Published var bottomInfoText: SendAmountViewModel.BottomInfoTextType?

    var useFiatCalculation: Bool {
        get { amountType == .fiat }
        set { amountType = newValue ? .fiat : .crypto }
    }

    // MARK: - Callbacks

    var onValueChanged: ((Decimal?) -> Void)?

    // MARK: - Private

    private(set) var sendAmountFormatter: SendAmountFormatter
    private let balanceConverter = BalanceConverter()
    private let balanceFormatter: BalanceFormatter = .init()
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory
    private var currencyId: String?
    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(
        tokenItem: TokenItem,
        fiatItem: FiatItem,
        possibleToConvertToFiat: Bool
    ) {
        let factory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory()
        prefixSuffixOptionsFactory = factory

        cryptoTextFieldViewModel = DecimalNumberTextFieldViewModel(maximumFractionDigits: tokenItem.decimalCount)
        fiatTextFieldViewModel = DecimalNumberTextFieldViewModel(maximumFractionDigits: fiatItem.fractionDigits)
        cryptoTextFieldOptions = factory.makeCryptoOptions(cryptoCurrencyCode: tokenItem.currencySymbol)
        fiatTextFieldOptions = factory.makeFiatOptions(fiatCurrencyCode: fiatItem.currencyCode)

        sendAmountFormatter = SendAmountFormatter(
            tokenItem: tokenItem,
            fiatItem: fiatItem,
            balanceFormatter: balanceFormatter
        )

        alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: .none, type: .crypto)
        self.possibleToConvertToFiat = possibleToConvertToFiat
        currencyId = tokenItem.currencyId

        bind()
    }

    // MARK: - Public API

    func updateAmountsUI(amount: SendAmount?) {
        cryptoTextFieldViewModel.update(value: amount?.crypto)
        fiatTextFieldViewModel.update(value: amount?.fiat)
        alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: amount, type: amountType)
    }

    func reconfigure(tokenItem: TokenItem, fiatItem: FiatItem, possibleToConvertToFiat: Bool) {
        currencyId = tokenItem.currencyId
        self.possibleToConvertToFiat = possibleToConvertToFiat

        cryptoTextFieldViewModel.update(maximumFractionDigits: tokenItem.decimalCount)
        cryptoTextFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(cryptoCurrencyCode: tokenItem.currencySymbol)

        fiatTextFieldViewModel.update(maximumFractionDigits: fiatItem.fractionDigits)
        fiatTextFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions(fiatCurrencyCode: fiatItem.currencyCode)

        sendAmountFormatter = SendAmountFormatter(
            tokenItem: tokenItem,
            fiatItem: fiatItem,
            balanceFormatter: balanceFormatter
        )
    }

    func updateFromExternalAmount(_ amount: SendAmount?, tokenItem: TokenItem) {
        guard let currencyId = tokenItem.currencyId else {
            alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: nil, type: amountType)
            return
        }

        let crypto = amount?.crypto
        let fiat = crypto.flatMap { balanceConverter.convertToFiat($0, currencyId: currencyId) }

        switch amountType {
        case .crypto:
            fiatTextFieldViewModel.update(value: fiat)
            let displayAmount = crypto.map { SendAmount(type: .typical(crypto: $0, fiat: fiat)) }
            alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: displayAmount, type: .crypto)
        case .fiat:
            cryptoTextFieldViewModel.update(value: crypto)
            fiatTextFieldViewModel.update(value: fiat)
            let displayAmount = fiat.map { SendAmount(type: .alternative(fiat: $0, crypto: crypto)) }
            alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: displayAmount, type: .fiat)
        }
    }
}

// MARK: - Private

private extension AmountInputFieldModel {
    func bind() {
        cryptoTextFieldViewModel.valuePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { model, value in
                guard model.amountType == .crypto else { return }
                model.onValueChanged?(value)
            }
            .store(in: &bag)

        fiatTextFieldViewModel.valuePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { model, value in
                guard model.amountType == .fiat else { return }
                model.onValueChanged?(value)
            }
            .store(in: &bag)

        $amountType
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { model, _ in
                model.refreshAlternativeAmount()
            }
            .store(in: &bag)
    }

    func refreshAlternativeAmount() {
        let crypto = cryptoTextFieldViewModel.value
        let fiat = crypto.flatMap { value in
            currencyId.flatMap { balanceConverter.convertToFiat(value, currencyId: $0) }
        }

        switch amountType {
        case .crypto:
            fiatTextFieldViewModel.update(value: fiat)
            let amount = crypto.map { SendAmount(type: .typical(crypto: $0, fiat: fiat)) }
            alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: amount, type: .crypto)
        case .fiat:
            fiatTextFieldViewModel.update(value: fiat)
            cryptoTextFieldViewModel.update(value: crypto)
            let amount = fiat.map { SendAmount(type: .alternative(fiat: $0, crypto: crypto)) }
            alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: amount, type: .fiat)
        }
    }
}
