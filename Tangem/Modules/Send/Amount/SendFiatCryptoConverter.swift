//
//  SendFiatCryptoConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class SendFiatCryptoConverter {
    var userInputAmount: AnyPublisher<DecimalNumberTextField.DecimalValue?, Never> {
        _userInputAmount.eraseToAnyPublisher()
    }

    var fiatAmount: AnyPublisher<Decimal?, Never> {
        _fiatCryptoValue.fiat.eraseToAnyPublisher()
    }

    var cryptoAmount: AnyPublisher<Decimal?, Never> {
        _fiatCryptoValue.crypto.eraseToAnyPublisher()
    }

    var modelAmount: AnyPublisher<Amount?, Never> {
        _fiatCryptoValue
            .crypto
            .map { [weak self] cryptoAmount in
                guard let self, let cryptoAmount else { return nil }

                return Amount(with: blockchain, type: amountType, value: cryptoAmount)
            }
            .eraseToAnyPublisher()
    }

    var amountAlternative: AnyPublisher<String?, Never> {
        Publishers.CombineLatest3(_useFiatCalculation, fiatAmount, cryptoAmount)
            .withWeakCaptureOf(self)
            .map { (self, parameters) -> String? in
                let (useFiatCalculation, fiatAmount, cryptoAmount) = parameters

                guard let cryptoAmount, let fiatAmount else { return nil }

                if useFiatCalculation {
                    return Amount(with: self.blockchain, type: self.amountType, value: cryptoAmount).string()
                } else {
                    return BalanceFormatter().formatFiatBalance(fiatAmount)
                }
            }
            .eraseToAnyPublisher()
    }

    private let blockchain: Blockchain
    private let amountType: Amount.AmountType
    private let cryptoCurrencyId: String?
    private let amountFractionDigits: Int

    private var _userInputAmount = CurrentValueSubject<DecimalNumberTextField.DecimalValue?, Never>(nil)
    private var _fiatCryptoValue = FiatCryptoValue(crypto: nil, fiat: nil)
    private var _useFiatCalculation = CurrentValueSubject<Bool, Never>(false)

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
            .removeDuplicates { $0?.value == $1?.value }
            .dropFirst()
            // If value == nil then continue chain to reset states to idle
            .filter { $0?.isInternal ?? true }
            .sink { [weak self] decimal in
                guard let self else { return }

                if let newAmountValue = fiatCryptoValue(from: decimal?.value, useFiatCalculation: _useFiatCalculation.value) {
                    _fiatCryptoValue.update(crypto: newAmountValue.crypto.value, fiat: newAmountValue.fiat.value)
                }
            }
            .store(in: &bag)
    }

    func setUserInputAmount(_ amount: DecimalNumberTextField.DecimalValue?) {
        _userInputAmount.send(amount)
    }

    func setModelAmount(_ amount: Decimal?) {
        guard let newAmountValue = fiatCryptoValue(from: amount, useFiatCalculation: false) else { return }

        _fiatCryptoValue.update(crypto: newAmountValue.crypto.value, fiat: newAmountValue.fiat.value)
        setTextFieldAmount()
    }

    func setUseFiatCalculation(_ useFiatCalculation: Bool) {
        _useFiatCalculation.send(useFiatCalculation)

        if _userInputAmount.value != nil {
            setTextFieldAmount()
        }
    }

    private func fiatCryptoValue(from amount: Decimal?, useFiatCalculation: Bool) -> FiatCryptoValue? {
        guard let amount else {
            return FiatCryptoValue(crypto: nil, fiat: nil)
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

        let newValue = FiatCryptoValue(crypto: newCryptoAmount, fiat: newFiatAmount)
        guard newValue != _fiatCryptoValue else {
            return nil
        }

        return newValue
    }

    private func setTextFieldAmount() {
        let newAmount = _useFiatCalculation.value ? _fiatCryptoValue.fiat.value : _fiatCryptoValue.crypto.value
        if let newAmount {
            _userInputAmount.send(.external(newAmount))
        } else {
            _userInputAmount.send(nil)
        }
    }
}

private extension SendFiatCryptoConverter {
    class FiatCryptoValue: Equatable {
        private(set) var crypto = CurrentValueSubject<Decimal?, Never>(nil)
        private(set) var fiat = CurrentValueSubject<Decimal?, Never>(nil)

        init(crypto: Decimal?, fiat: Decimal? = nil) {
            update(crypto: crypto, fiat: fiat)
        }

        func update(crypto: Decimal?, fiat: Decimal?) {
            self.crypto.send(crypto)
            self.fiat.send(fiat)
        }

        static func == (left: SendFiatCryptoConverter.FiatCryptoValue, right: SendFiatCryptoConverter.FiatCryptoValue) -> Bool {
            left.crypto.value == right.crypto.value && left.fiat.value == right.fiat.value
        }
    }
}
