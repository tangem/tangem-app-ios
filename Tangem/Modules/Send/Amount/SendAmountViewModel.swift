//
//  SendAmountViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

#warning("[REDACTED_TODO_COMMENT]")

protocol SendAmountViewModelInput {
    var amountPublisher: AnyPublisher<SendAmount?, Never> { get }
    var amountError: AnyPublisher<Error?, Never> { get }

    var currentAmount: SendAmount? { get }
    var blockchain: Blockchain { get }
    var amountType: Amount.AmountType { get }

    func setAmount(_ amount: Amount?)
}

protocol SendAmountViewModelDelegate: AnyObject {
    func didTapMaxAmount()
}

class SendAmountViewModel: ObservableObject, Identifiable {
    let walletName: String
    let balance: String
    let tokenIconInfo: TokenIconInfo
    let cryptoCurrencyId: String?
    let cryptoCurrencyCode: String
    let fiatCurrencyCode: String
    let amountFractionDigits: Int

    @Published var amount: DecimalNumberTextField.DecimalValue? = nil
    @Published var isFiatCalculation = false
    @Published var amountAlternative: String = ""
    @Published var error: String?

    private var cryptoAmount: Decimal? = nil

    weak var delegate: SendAmountViewModelDelegate?

    private let input: SendAmountViewModelInput
    private var doingFiatCryptoConversion = false // [REDACTED_TODO_COMMENT]
    private var bag: Set<AnyCancellable> = []

    init(input: SendAmountViewModelInput, walletInfo: SendWalletInfo) {
        self.input = input
        walletName = walletInfo.walletName
        balance = walletInfo.balance
        tokenIconInfo = walletInfo.tokenIconInfo
        amountFractionDigits = walletInfo.amountFractionDigits

        cryptoCurrencyId = walletInfo.cryptoCurrencyId
        cryptoCurrencyCode = walletInfo.cryptoCurrencyCode
        fiatCurrencyCode = walletInfo.fiatCurrencyCode

        bind(from: input)
    }

    func didTapMaxAmount() {
        delegate?.didTapMaxAmount()
    }

    private func bind(from input: SendAmountViewModelInput) {
        input
            .amountError
            .map { $0?.localizedDescription }
            .assign(to: \.error, on: self, ownership: .weak)
            .store(in: &bag)

        input
            .amountPublisher
            .removeDuplicates()
            .sink { [weak self] amount in
                guard
                    let self,
                    case .internal = amount
                else {
                    return
                }

                let newAmount = fromAmount(amount?.amount)
                print("ZZZ model amount changed", amount?.amount, newAmount)
                if self.amount != newAmount {
                    self.amount = newAmount
                }
            }
            .store(in: &bag)

        $amount
            .removeDuplicates()
            .sink { [weak self] amount in
                guard let self else { return }

                guard !doingFiatCryptoConversion else {
                    print("ZZZ entered amount changed", amount, "(skipping)")
                    return
                }

                // internal?
                if self.amount?.value == amount?.value {
                    print("ZZZ entered amount same", amount, "(skipping)")
                    return
                }

                let newAmount = toAmount(amount)
                print("ZZZ entered amount changed", amount, newAmount)
                input.setAmount(newAmount)
            }
            .store(in: &bag)

        $isFiatCalculation
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] isFiatCalculation in
                guard let self else { return }

                doingFiatCryptoConversion = true
                defer {
                    doingFiatCryptoConversion = false
                }

                let newAmount = convert(input: amount, isFiatCalculation: isFiatCalculation)
                print("ZZZ switched", amount, newAmount)
                if amount != newAmount {
                    amount = newAmount
                }
            }
            .store(in: &bag)
    }

    private func convert(input: DecimalNumberTextField.DecimalValue?, isFiatCalculation: Bool) -> DecimalNumberTextField.DecimalValue? {
        guard
            let input,
            let cryptoCurrencyId else {
            return nil
        }

        let inputValue = input.value
        let output: Decimal?
        let scale: Int
        if isFiatCalculation {
            scale = 2
            output = BalanceConverter().convertToFiat(value: inputValue, from: cryptoCurrencyId)
        } else {
            scale = amountFractionDigits
            if case .external(let currentCryptoAmount) = self.input.currentAmount {
                output = currentCryptoAmount?.value
            } else {
                output = BalanceConverter().convertFromFiat(value: inputValue, to: cryptoCurrencyId)
            }
        }

        guard let output else { return nil }

        return DecimalNumberTextField.DecimalValue.external(output.rounded(scale: scale))
    }

    private func fromAmount(_ cryptoAmount: Amount?) -> DecimalNumberTextField.DecimalValue? {
        guard
            let cryptoAmount,
            let cryptoCurrencyId
        else {
            return nil
        }

        let decimal: Decimal
        if isFiatCalculation {
            guard let convertedDecimal = BalanceConverter().convertToFiat(value: cryptoAmount.value, from: cryptoCurrencyId) else {
                return nil
            }
            decimal = convertedDecimal
        } else {
            decimal = cryptoAmount.value
        }

        return DecimalNumberTextField.DecimalValue.external(decimal)
    }

    private func toAmount(_ enteredDecimalValue: DecimalNumberTextField.DecimalValue?) -> Amount? {
        guard
            let enteredDecimalValue,
            let cryptoCurrencyId
        else {
            return nil
        }

        let decimal: Decimal
        if isFiatCalculation {
            guard let convertedDecimal = BalanceConverter().convertFromFiat(value: enteredDecimalValue.value, to: cryptoCurrencyId) else {
                return nil
            }
            decimal = convertedDecimal
        } else {
            decimal = enteredDecimalValue.value
        }

        return Amount(with: input.blockchain, type: input.amountType, value: decimal)
    }
}
