//
//  SendFiatCryptoAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendFiatCryptoAdapterInput: AnyObject {
    var amountPublisher: AnyPublisher<DecimalNumberTextField.DecimalValue?, Never> { get }

    func setUserInputAmount(_ userInputAmount: DecimalNumberTextField.DecimalValue?)
}

protocol SendFiatCryptoAdapterOutput: AnyObject {
    func setAmount(_ decimal: Decimal?)
}

class SendFiatCryptoAdapter {
    var amountAlternative: AnyPublisher<String?, Never> {
        Publishers.CombineLatest(_useFiatCalculation, $_fiatCryptoValue)
            .withWeakCaptureOf(self)
            .map { thisSendFiatCryptoAdapter, params -> String? in
                let (useFiatCalculation, fiatCryptoValue) = params

                guard let cryptoValue = fiatCryptoValue.crypto, let fiatValue = fiatCryptoValue.fiat else { return nil }

                let formatter = BalanceFormatter()
                if useFiatCalculation {
                    let formattingOption = BalanceFormattingOptions(
                        minFractionDigits: BalanceFormattingOptions.defaultCryptoFormattingOptions.minFractionDigits,
                        maxFractionDigits: thisSendFiatCryptoAdapter.decimals,
                        roundingType: BalanceFormattingOptions.defaultCryptoFormattingOptions.roundingType
                    )

                    return formatter.formatCryptoBalance(
                        cryptoValue,
                        currencyCode: thisSendFiatCryptoAdapter.currencySymbol,
                        formattingOptions: formattingOption
                    )
                } else {
                    return formatter.formatFiatBalance(fiatValue)
                }
            }
            .eraseToAnyPublisher()
    }

    private let currencySymbol: String
    private let decimals: Int

    @Published private var _fiatCryptoValue: FiatCryptoValue
    private var _useFiatCalculation = CurrentValueSubject<Bool, Never>(false)

    private weak var input: SendFiatCryptoAdapterInput?
    private weak var output: SendFiatCryptoAdapterOutput?

    private var bag: Set<AnyCancellable> = []

    init(
        cryptoCurrencyId: String?,
        currencySymbol: String,
        decimals: Int
    ) {
        self.currencySymbol = currencySymbol
        self.decimals = decimals
        _fiatCryptoValue = FiatCryptoValue(decimals: decimals, cryptoCurrencyId: cryptoCurrencyId)

        bind()
    }

    func setAmount(_ decimal: DecimalNumberTextField.DecimalValue?) {
        if _useFiatCalculation.value {
            _fiatCryptoValue.setFiat(decimal?.value)
        } else {
            _fiatCryptoValue.setCrypto(decimal?.value)
        }
    }

    func setUseFiatCalculation(_ useFiatCalculation: Bool) {
        _useFiatCalculation.send(useFiatCalculation)
        setUserInputAmount()
    }

    func setCrypto(_ decimal: Decimal?) {
        _fiatCryptoValue.setCrypto(decimal)
        setUserInputAmount()
    }

    func setOutput(_ output: SendFiatCryptoAdapterOutput) {
        self.output = output
    }

    func setInput(_ input: SendFiatCryptoAdapterInput) {
        self.input = input
    }

    private func bind() {
        $_fiatCryptoValue
            .map(\.crypto)
            .sink { [weak self] crypto in
                self?.output?.setAmount(crypto)
            }
            .store(in: &bag)
    }

    private func setUserInputAmount() {
        let newAmount = _useFiatCalculation.value ? _fiatCryptoValue.fiat : _fiatCryptoValue.crypto
        if let newAmount {
            input?.setUserInputAmount(.external(newAmount))
        } else {
            input?.setUserInputAmount(nil)
        }
    }
}

private extension SendFiatCryptoAdapter {
    struct FiatCryptoValue {
        private(set) var crypto: Decimal?
        private(set) var fiat: Decimal?

        private let decimals: Int
        private let cryptoCurrencyId: String?
        private let balanceConverter = BalanceConverter()

        init(decimals: Int, cryptoCurrencyId: String?) {
            self.decimals = decimals
            self.cryptoCurrencyId = cryptoCurrencyId
        }

        mutating func setCrypto(_ crypto: Decimal?) {
            guard self.crypto != crypto else { return }

            self.crypto = crypto

            if let cryptoCurrencyId, let crypto {
                fiat = balanceConverter.convertToFiat(value: crypto, from: cryptoCurrencyId)?.rounded(scale: 2)
            } else {
                fiat = nil
            }
        }

        mutating func setFiat(_ fiat: Decimal?) {
            guard self.fiat != fiat else { return }

            self.fiat = fiat

            if let cryptoCurrencyId, let fiat {
                crypto = balanceConverter.convertFromFiat(value: fiat, to: cryptoCurrencyId)?.rounded(scale: decimals)
            } else {
                crypto = nil
            }
        }
    }
}
