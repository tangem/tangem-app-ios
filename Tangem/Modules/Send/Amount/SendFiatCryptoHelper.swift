//
//  SendFiatCryptoHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class SendFiatCryptoHelper {
    var userInputAmount: AnyPublisher<Decimal?, Never> {
        _userInputAmount.eraseToAnyPublisher()
    }

    var modelAmount: AnyPublisher<Amount?, Never> {
        _cryptoAmount
            .map { [weak self] in
                guard let self else { return nil }

                if let value = $0 {
                    return Amount(with: blockchain, type: amountType, value: value)
                } else {
                    return nil
                }
            }

            .eraseToAnyPublisher()
    }

    private let blockchain: Blockchain
    private let amountType: Amount.AmountType
    private let cryptoCurrencyId: String?
    private let amountFractionDigits: Int

    private var _userInputAmount = CurrentValueSubject<Decimal?, Never>(nil)

    private var _useFiatCalculation = CurrentValueSubject<Bool, Never>(false)

    private var inputTrigger: InputTrigger = .keyboard

    private var _cryptoAmount = CurrentValueSubject<Decimal?, Never>(nil)
    private var fiatAmount: Decimal?

    private var bag: Set<AnyCancellable> = []

    init(
        blockchain: Blockchain,
        amountType: Amount.AmountType,
        cryptoCurrencyId: String?,
        amountFractionDigits: Int
    ) {
        self.blockchain = blockchain
        self.amountType = amountType
        self.cryptoCurrencyId = cryptoCurrencyId
        self.amountFractionDigits = amountFractionDigits

        bind()
    }

    func bind() {
        _userInputAmount
            .removeDuplicates()
            .sink { [weak self] decimal in
                guard let self else { return }

                guard inputTrigger == .keyboard else {
                    inputTrigger = .keyboard
                    return
                }

                setModelAmount2(decimal)
            }
            .store(in: &bag)
    }

    func didChooseMaxAmount() {
        inputTrigger = .maxAmount
    }

    func setUserInputAmount(_ amount: Decimal?) {
        _userInputAmount.send(amount)
    }

    func setModelAmount(_ amount: Decimal?) {
        setViewAmount(amount, inputTrigger: inputTrigger)
    }

    func setUseFiatCalculation(_ useFiatCalculation: Bool) {
        guard _userInputAmount.value != nil else {
            return
        }

        inputTrigger = .currencySelector

        _useFiatCalculation.send(useFiatCalculation)
        setTextFieldAmount(useFiatCalculation: useFiatCalculation)
    }

    private func amountPair(from amount: Decimal?, useFiatCalculation: Bool) -> (cryptoAmount: Decimal?, fiatAmount: Decimal?)? {
        guard let amount else {
            return (nil, nil)
        }

        let newCryptoAmount: Decimal?
        let newFiatAmount: Decimal?

        if let cryptoCurrencyId {
            let balanceConverter = BalanceConverter()
            if useFiatCalculation {
                newCryptoAmount = balanceConverter.convertFromFiat(value: amount, to: cryptoCurrencyId)?.rounded(scale: amountFractionDigits)
                newFiatAmount = amount
            } else {
                newCryptoAmount = amount
                newFiatAmount = balanceConverter.convertToFiat(value: amount, from: cryptoCurrencyId)?.rounded(scale: 2)
            }
        } else {
            newCryptoAmount = amount
            newFiatAmount = nil
        }

        guard
            let newCryptoAmount,
            newCryptoAmount != _cryptoAmount.value || newFiatAmount != fiatAmount
        else {
            return nil
        }

        return (newCryptoAmount, newFiatAmount)
    }

    private func setViewAmount(_ amount: Decimal?, inputTrigger: InputTrigger) {
        guard let (newCryptoAmount, newFiatAmount) = amountPair(from: amount, useFiatCalculation: false) else { return }

        _cryptoAmount.send(newCryptoAmount)
        if inputTrigger != .keyboard {
            fiatAmount = newFiatAmount
            setTextFieldAmount(useFiatCalculation: _useFiatCalculation.value)
        }
    }

    private func setModelAmount2(_ amount: Decimal?) {
        let useFiatCalculation = _useFiatCalculation.value
        guard
            let (newCryptoAmount, newFiatAmount) = amountPair(from: amount, useFiatCalculation: useFiatCalculation)
        else {
            return
        }

        _cryptoAmount.send(newCryptoAmount)
        fiatAmount = newFiatAmount
    }

    private func setTextFieldAmount(useFiatCalculation: Bool) {
        let newAmount = useFiatCalculation ? fiatAmount : _cryptoAmount.value
        _userInputAmount.send(newAmount)
    }
}

private extension SendFiatCryptoHelper {
    enum InputTrigger {
        case keyboard
        case currencySelector
        case maxAmount
    }
}

// [REDACTED_TODO_COMMENT]
// [REDACTED_TODO_COMMENT]
