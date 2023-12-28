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
    var amountPublisher: AnyPublisher<Amount?, Never> { get }
    var amountError: AnyPublisher<Error?, Never> { get }

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
            .sink { [weak self] amount in
                guard let self else { return }

                if doingFiatCryptoConversion {
                    doingFiatCryptoConversion = false
                    return
                }

                print("zzz input amount changed", amount?.value, isFiatCalculation)

                let newAmount = fromAmount(amount)
                if self.amount != newAmount {
                    self.amount = newAmount
                }
            }
            .store(in: &bag)

        $amount
            .debounce(for: 0.1, scheduler: RunLoop.main)
            .sink { [weak self] amount in
                guard let self else { return }

                if doingFiatCryptoConversion {
                    doingFiatCryptoConversion = false
                    return
                }
                print("zzz entered amount changed", amount?.value, isFiatCalculation)

                let newAmount = toAmount(amount)
                input.setAmount(newAmount)
            }
            .store(in: &bag)

        $isFiatCalculation
            .dropFirst()
            .removeDuplicates()
            .debounce(for: 0.1, scheduler: RunLoop.main)
            .sink { [weak self] isFiatCalculation in

                guard let self else { return }
                #warning("[REDACTED_TODO_COMMENT]")

                print(isFiatCalculation)
                doingFiatCryptoConversion = true
                amount = convert(input: amount, isFiatCalculation: isFiatCalculation)
//                input.setAmount(convert(input: amount, isFiatCalculation: isFiatCalculation))
            }
            .store(in: &bag)
    }

    private func convert(input: DecimalNumberTextField.DecimalValue?, isFiatCalculation: Bool) -> DecimalNumberTextField.DecimalValue? {
//    private func convert(input: DecimalNumberTextField.DecimalValue?, isFiatCalculation: Bool) -> Amount? {
        guard let cryptoCurrencyId else { return nil }

        guard let input else { return nil }

        let inputValue = input.value
        let output: Decimal?
        if isFiatCalculation {
            output = BalanceConverter().convertToFiat(value: inputValue, from: cryptoCurrencyId)
        } else {
            output = BalanceConverter().convertFromFiat(value: inputValue, to: cryptoCurrencyId)
        }

        guard let output else { return nil }

//        return Amount(with: self.input.blockchain, type: self.input.amountType, value: output)

        return DecimalNumberTextField.DecimalValue.external(output)
    }

    private func fromAmount(_ cryptoAmount: Amount?) -> DecimalNumberTextField.DecimalValue? {
        guard let cryptoCurrencyId else { return nil }
        guard let cryptoAmount else { return nil }

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
        guard let cryptoCurrencyId else { return nil }
        guard let enteredDecimalValue else { return nil }

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
