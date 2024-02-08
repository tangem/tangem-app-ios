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

                return Amount(type: amountType, currencySymbol: currencySymbol, value: cryptoAmount, decimals: decimals)
            }
            .eraseToAnyPublisher()
    }

    var amountAlternative: AnyPublisher<String?, Never> {
        Publishers.CombineLatest3(_useFiatCalculation, fiatAmount, cryptoAmount)
            .map { [weak self] useFiatCalculation, fiatAmount, cryptoAmount -> String? in
                guard let self, let cryptoAmount, let fiatAmount else { return nil }

                if useFiatCalculation {
                    return Amount(type: amountType, currencySymbol: currencySymbol, value: cryptoAmount, decimals: decimals).string()
                } else {
                    return BalanceFormatter().formatFiatBalance(fiatAmount)
                }
            }
            .eraseToAnyPublisher()
    }

    private let amountType: Amount.AmountType
    private let currencySymbol: String
    private let decimals: Int

    private var _userInputAmount = CurrentValueSubject<DecimalNumberTextField.DecimalValue?, Never>(nil)
    private var _fiatCryptoValue: FiatCryptoValue
    private var _useFiatCalculation = CurrentValueSubject<Bool, Never>(false)

    private var bag: Set<AnyCancellable> = []

    init(
        amountType: Amount.AmountType,
        cryptoCurrencyId: String?,
        currencySymbol: String,
        decimals: Int
    ) {
        self.amountType = amountType
        self.currencySymbol = currencySymbol
        self.decimals = decimals
        _fiatCryptoValue = FiatCryptoValue(decimals: decimals, cryptoCurrencyId: cryptoCurrencyId)

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

                if _useFiatCalculation.value {
                    _fiatCryptoValue.setFiat(decimal?.value)
                } else {
                    _fiatCryptoValue.setCrypto(decimal?.value)
                }
            }
            .store(in: &bag)

        Publishers.CombineLatest3(_useFiatCalculation, _fiatCryptoValue.crypto, _fiatCryptoValue.fiat)
            .sink { [weak self] _, _, _ in
                self?.setTextFieldAmount()
            }
            .store(in: &bag)
    }

    func setUserInputAmount(_ amount: DecimalNumberTextField.DecimalValue?) {
        _userInputAmount.send(amount)
    }

    func setModelAmount(_ amount: Decimal?) {
        _fiatCryptoValue.setCrypto(amount)
    }

    func setUseFiatCalculation(_ useFiatCalculation: Bool) {
        _useFiatCalculation.send(useFiatCalculation)

        if _userInputAmount.value != nil {
            setTextFieldAmount()
        }
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
    class FiatCryptoValue {
        private(set) var crypto = CurrentValueSubject<Decimal?, Never>(nil)
        private(set) var fiat = CurrentValueSubject<Decimal?, Never>(nil)

        private let decimals: Int
        private let cryptoCurrencyId: String?
        private let balanceConverter = BalanceConverter()

        init(decimals: Int, cryptoCurrencyId: String?) {
            self.decimals = decimals
            self.cryptoCurrencyId = cryptoCurrencyId
        }

        func setCrypto(_ crypto: Decimal?) {
            guard self.crypto.value != crypto else { return }

            self.crypto.send(crypto)

            if let cryptoCurrencyId, let crypto {
                fiat.send(balanceConverter.convertToFiat(value: crypto, from: cryptoCurrencyId)?.rounded(scale: 2))
            } else {
                fiat.send(nil)
            }
        }

        func setFiat(_ fiat: Decimal?) {
            guard self.fiat.value != fiat else { return }

            self.fiat.send(fiat)

            if let cryptoCurrencyId, let fiat {
                crypto.send(balanceConverter.convertFromFiat(value: fiat, to: cryptoCurrencyId)?.rounded(scale: decimals))
            } else {
                crypto.send(nil)
            }
        }
    }
}
