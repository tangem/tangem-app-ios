//
//  SendAmountViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

#warning("TODO: move these to different files?")

protocol AmountErrorProvider: AnyObject {
    var amountError: AnyPublisher<Error?, Never> { get }
}

protocol SendAmountViewModelInput {
    func setAmount(_ amount: Amount?)
}

class SendAmountViewModel: ObservableObject, Identifiable {
    let walletName: String
    let balance: String
    let tokenIconInfo: TokenIconInfo
    let currencyPickerDisabled: Bool
    let cryptoIconURL: URL?
    let cryptoCurrencyCode: String
    let fiatIconURL: URL?
    let fiatCurrencyCode: String
    let fiatCurrencySymbol: String
    let amountFractionDigits: Int

    @Published var userInputDisabled = true
    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var useFiatCalculation = false
    @Published var amountAlternative: String?
    @Published var error: String?
    @Published var animatingAuxiliaryViewsOnAppear = false

    var currentFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions {
        useFiatCalculation ? fiatFieldOptions : cryptoFieldOptions
    }

    var isValid: AnyPublisher<Bool, Never> {
        validatedAmount
            .map {
                $0 != nil
            }
            .eraseToAnyPublisher()
    }

    var didProperlyDisappear = false

    private weak var transactionValidator: TransactionValidator?
    private weak var fiatCryptoAdapter: SendFiatCryptoAdapter?

    private let input: SendAmountViewModelInput
    private let walletInfo: SendWalletInfo
    private let cryptoFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    private let fiatFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    private let validatedAmount = CurrentValueSubject<Amount?, Never>(nil)
    private let _amountError = CurrentValueSubject<Error?, Never>(nil)
    private var userInputAmount = CurrentValueSubject<Amount?, Never>(nil)
    private let balanceValue: Decimal?
    private var bag: Set<AnyCancellable> = []

    init(input: SendAmountViewModelInput, transactionValidator: TransactionValidator, fiatCryptoAdapter: SendFiatCryptoAdapter, walletInfo: SendWalletInfo) {
        self.input = input
        self.walletInfo = walletInfo
        self.transactionValidator = transactionValidator
        self.fiatCryptoAdapter = fiatCryptoAdapter
        balanceValue = walletInfo.balanceValue
        walletName = walletInfo.walletName
        balance = walletInfo.balance
        tokenIconInfo = walletInfo.tokenIconInfo
        amountFractionDigits = walletInfo.amountFractionDigits
        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: walletInfo.amountFractionDigits)

        currencyPickerDisabled = !walletInfo.canUseFiatCalculation

        cryptoIconURL = walletInfo.cryptoIconURL
        cryptoCurrencyCode = walletInfo.cryptoCurrencyCode

        let localizedCurrencySymbol = Locale.current.localizedCurrencySymbol(forCurrencyCode: walletInfo.fiatCurrencyCode)
        fiatIconURL = walletInfo.fiatIconURL
        fiatCurrencyCode = walletInfo.fiatCurrencyCode
        fiatCurrencySymbol = localizedCurrencySymbol ?? walletInfo.fiatCurrencyCode

        let factory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory(
            cryptoCurrencyCode: walletInfo.cryptoCurrencyCode,
            fiatCurrencyCode: walletInfo.fiatCurrencyCode
        )
        cryptoFieldOptions = factory.makeCryptoOptions()
        fiatFieldOptions = factory.makeFiatOptions()

        bind(from: input)
    }

    func onAppear() {
        fiatCryptoAdapter?.setCrypto(userInputAmount.value?.value)

        if animatingAuxiliaryViewsOnAppear {
            Analytics.log(.sendScreenReopened, params: [.source: .amount])
        } else {
            Analytics.log(.sendAmountScreenOpened)
        }
    }

    func setUserInputDisabled(_ userInputDisabled: Bool) {
        self.userInputDisabled = userInputDisabled
    }

    func setUserInputAmount(_ userInputAmount: Decimal?) {
        decimalNumberTextFieldViewModel.update(value: userInputAmount)
    }

    func didTapMaxAmount() {
        guard let balanceValue else { return }

        Analytics.log(.sendMaxAmountTapped)

        provideButtonHapticFeedback()

        fiatCryptoAdapter?.setCrypto(balanceValue)
    }

    private func bind(from input: SendAmountViewModelInput) {
        _amountError
            .map { $0?.localizedDescription }
            .assign(to: \.error, on: self, ownership: .weak)
            .store(in: &bag)

        decimalNumberTextFieldViewModel
            .valuePublisher
            .sink { [weak self] decimal in
                self?.fiatCryptoAdapter?.setAmount(decimal)
            }
            .store(in: &bag)

        $useFiatCalculation
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, useFiatCalculation in
                let maximumFractionDigits = useFiatCalculation ? 2 : viewModel.amountFractionDigits
                viewModel.decimalNumberTextFieldViewModel.update(maximumFractionDigits: maximumFractionDigits)
                viewModel.provideSelectionHapticFeedback()
                viewModel.fiatCryptoAdapter?.setUseFiatCalculation(useFiatCalculation)
            }
            .store(in: &bag)

        fiatCryptoAdapter?
            .formattedAmountAlternativePublisher
            .assign(to: \.amountAlternative, on: self, ownership: .weak)
            .store(in: &bag)

        userInputAmount
            .removeDuplicates {
                $0 == $1
            }
            .sink { [weak self] amount in
                self?.updateAndValidateAmount(amount)
            }
            .store(in: &bag)
    }

    private func updateAndValidateAmount(_ newAmount: Amount?) {
        let validatedAmount: Amount?
        let amountError: Error?

        if let newAmount {
            do {
                let amount: Amount
                amount = newAmount
                try transactionValidator?.validate(amount: amount)

                validatedAmount = amount
                amountError = nil
            } catch let validationError {
                validatedAmount = nil
                amountError = validationError
            }
        } else {
            validatedAmount = nil
            amountError = nil
        }

        self.validatedAmount.send(validatedAmount)
        _amountError.send(amountError)
    }

    private func provideButtonHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func provideSelectionHapticFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

extension SendAmountViewModel: SendFiatCryptoAdapterOutput {
    func setAmount(_ amount: Amount?) {
        let newAmount: Amount? = (amount?.isZero ?? true) ? nil : amount

        guard userInputAmount.value != newAmount else { return }

        print("ZZZ [amount] vm changed", amount?.value)
        userInputAmount.send(newAmount)
    }

    func setAmount(_ decimal: Decimal?) {
        let amount: Amount?
        if let decimal {
            amount = Amount(type: walletInfo.amountType, currencySymbol: walletInfo.cryptoCurrencyCode, value: decimal, decimals: walletInfo.decimalCount)
        } else {
            amount = nil
        }
        setAmount(amount)
    }
}

extension SendAmountViewModel: SendStepSaveable {
    func save() {
        input.setAmount(validatedAmount.value)
    }
}

extension SendAmountViewModel: AuxiliaryViewAnimatable {}

extension SendAmountViewModel: AmountErrorProvider {
    var amountError: AnyPublisher<Error?, Never> {
        _amountError.eraseToAnyPublisher()
    }
}

extension SendAmountViewModel: SendFiatCryptoAdapterInput {
    var amountPublisher: AnyPublisher<Decimal?, Never> {
        decimalNumberTextFieldViewModel.valuePublisher
    }
}
