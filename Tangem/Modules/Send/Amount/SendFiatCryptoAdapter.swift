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

class SendFiatCryptoAdapter {
    var amountAlternative: AnyPublisher<String?, Never> {
        Publishers.CombineLatest3(_useFiatCalculation, _fiatCryptoValue.fiat, _fiatCryptoValue.crypto)
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

    #warning("[REDACTED_TODO_COMMENT]")
    private weak var viewModel: SendAmountViewModel?
    private weak var sendModel: SendModel?

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
    }

    func setSendModel(_ sendModel: SendModel) {
        self.sendModel = sendModel

        sendModel
            .amountInputPublisher
            .sink { [weak self] amount in
                guard let self else { return }
                _fiatCryptoValue.setCrypto(amount?.value)
            }
            .store(in: &bag)
    }

    func setViewModel(_ viewModel: SendAmountViewModel) {
        self.viewModel = viewModel

        _userInputAmount
            .removeDuplicates { $0?.value == $1?.value }
            .dropFirst()
            // If value == nil then continue chain to reset states to idle
//            .filter { $0?.isInternal ?? true }
            .sink { [weak self] decimal in
                guard let self else { return }

                if _useFiatCalculation.value {
                    _fiatCryptoValue.setFiat(decimal?.value)
                } else {
                    _fiatCryptoValue.setCrypto(decimal?.value)
                }
            }
            .store(in: &bag)

        viewModel
            .$amount
            .removeDuplicates { $0?.value == $1?.value }
            .dropFirst()
            // If value == nil then continue chain to reset states to idle
//            .filter { $0?.isInternal ?? true }
            .sink { [weak self] v in
                print("zzz viewModel update amount", v)
//                self?.setUserInputAmount(v)
                self?._userInputAmount.send(v)
            }
            .store(in: &bag)

        viewModel
            .$useFiatCalculation
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] useFiatCalculation in
                guard let self else { return }
                print("zzz view model update useFiatCalculation", useFiatCalculation)
//                self?.setUseFiatCalculation(useFiatCalculation)

                _useFiatCalculation.send(useFiatCalculation)

                if _userInputAmount.value != nil {
                    setTextFieldAmount()
                }
            }
            .store(in: &bag)

        modelAmount
            .sink { [weak self] modelAmount in
                self?.sendModel?.setAmount(modelAmount)
            }
            .store(in: &bag)
    }

    private func setTextFieldAmount() {
        let newAmount = _useFiatCalculation.value ? _fiatCryptoValue.fiat.value : _fiatCryptoValue.crypto.value
        if let newAmount {
            viewModel?.setUserInputAmount(.external(newAmount))
        } else {
            viewModel?.setUserInputAmount(nil)
        }
    }
}

private extension SendFiatCryptoAdapter {
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
