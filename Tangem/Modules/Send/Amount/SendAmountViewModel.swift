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

    weak var delegate: SendAmountViewModelDelegate?

    private var inputTrigger: InputTrigger = .keyboard
    private var cryptoAmount: Decimal? = nil
    private var fiatAmount: Decimal? = nil

    private let input: SendAmountViewModelInput
    private var bag: Set<AnyCancellable> = []

    init(input: SendAmountViewModelInput, walletInfo: SendWalletInfo) {
        self.input = input
        walletName = walletInfo.walletName
        balance = walletInfo.balance
        tokenIconInfo = walletInfo.tokenIconInfo
        amountFractionDigits = walletInfo.amountFractionDigits

        cryptoCurrencyId = walletInfo.currencyId
        cryptoCurrencyCode = walletInfo.cryptoCurrencyCode
        fiatCurrencyCode = walletInfo.fiatCurrencyCode

        bind(from: input)
    }

    func didTapMaxAmount() {
        inputTrigger = .maxAmount
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
                guard let self else { return }

                setViewAmount(amount?.value, inputTrigger: inputTrigger)
            }
            .store(in: &bag)

        $amount
            .removeDuplicates()
            .sink { [weak self] amount in
                guard let self else { return }

                guard inputTrigger == .keyboard else {
                    inputTrigger = .keyboard
                    return
                }

                if self.amount?.value == amount?.value {
                    return
                }

                setModelAmount(amount?.value)
            }
            .store(in: &bag)

        $isFiatCalculation
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] isFiatCalculation in
                guard let self else { return }

                inputTrigger = .currencySelector
                updateViewAmount(isFiatCalculation: isFiatCalculation)
            }
            .store(in: &bag)
    }

    private func updateViewAmount(isFiatCalculation: Bool) {
        let newAmount: Decimal?

        if isFiatCalculation {
            newAmount = fiatAmount
        } else {
            newAmount = cryptoAmount
        }

        if let newAmount {
            amount = .external(newAmount)
        } else {
            amount = nil
        }
    }

    private func amountPair(from amount: Decimal?, isFiatCalculation: Bool) -> (cryptoAmount: Decimal?, fiatAmount: Decimal?)? {
        guard let amount else {
            return (nil, nil)
        }

        let newCryptoAmount: Decimal?
        let newFiatAmount: Decimal?

        if let cryptoCurrencyId {
            if isFiatCalculation {
                newCryptoAmount = BalanceConverter().convertFromFiat(value: amount, to: cryptoCurrencyId)?.rounded(scale: amountFractionDigits)
                newFiatAmount = amount
            } else {
                newCryptoAmount = amount
                newFiatAmount = BalanceConverter().convertToFiat(value: amount, from: cryptoCurrencyId)?.rounded(scale: 2)
            }
        } else {
            newCryptoAmount = amount
            newFiatAmount = nil
        }

        guard
            let newCryptoAmount,
            newCryptoAmount != cryptoAmount || newFiatAmount != fiatAmount
        else {
            return nil
        }

        return (newCryptoAmount, newFiatAmount)
    }

    private func setViewAmount(_ amount: Decimal?, inputTrigger: InputTrigger) {
        guard let (newCryptoAmount, newFiatAmount) = amountPair(from: amount, isFiatCalculation: false) else { return }

        cryptoAmount = newCryptoAmount
        if inputTrigger != .keyboard {
            fiatAmount = newFiatAmount
            updateViewAmount(isFiatCalculation: isFiatCalculation)
        }
    }

    private func setModelAmount(_ amount: Decimal?) {
        guard let (newCryptoAmount, newFiatAmount) = amountPair(from: amount, isFiatCalculation: isFiatCalculation) else { return }

        cryptoAmount = newCryptoAmount
        fiatAmount = newFiatAmount

        let newAmount: Amount?
        if let newCryptoAmount {
            newAmount = Amount(with: input.blockchain, type: input.amountType, value: newCryptoAmount)
        } else {
            newAmount = nil
        }
        input.setAmount(newAmount)
    }
}

private extension SendAmountViewModel {
    enum InputTrigger {
        case keyboard
        case currencySelector
        case maxAmount
    }
}
