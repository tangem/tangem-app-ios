//
//  CryptoFiatAmount.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CryptoFiatAmount {
    var crypto: Decimal? { _crypto.value }
    var fiat: Decimal? { _fiat.value }

    var cryptoPublisher: AnyPublisher<Decimal?, Never> {
        _crypto.eraseToAnyPublisher()
    }

    var fiatPublisher: AnyPublisher<Decimal?, Never> {
        _fiat.eraseToAnyPublisher()
    }

    var cryptoFormatted: String {
        _cryptoFormatted.value
    }

    var fiatFormatted: String {
        _fiatFormatted.value
    }

    var cryptoFormattedPublisher: AnyPublisher<String, Never> {
        _cryptoFormatted.eraseToAnyPublisher()
    }

    var fiatFormattedPublisher: AnyPublisher<String, Never> {
        _fiatFormatted.eraseToAnyPublisher()
    }

    private var _crypto = CurrentValueSubject<Decimal?, Never>(nil)
    private var _fiat = CurrentValueSubject<Decimal?, Never>(nil)

    private var _cryptoFormatted = CurrentValueSubject<String, Never>("")
    private var _fiatFormatted = CurrentValueSubject<String, Never>("")

    private let amountFractionDigits: Int
    private let currencyId: String?
    private let currencyCode: String

    init(amountFractionDigits: Int, currencyId: String?, currencyCode: String) {
        self.amountFractionDigits = amountFractionDigits
        self.currencyId = currencyId
        self.currencyCode = currencyCode
    }

    func setCrypto(_ crypto: Decimal?) {
        let fiat: Decimal?
        if let crypto,
           let currencyId,
           let convertedFiat = BalanceConverter().convertToFiat(value: crypto, from: currencyId)?.rounded(scale: 2) {
            fiat = convertedFiat
        } else {
            fiat = nil
        }
        setCryptoFiatValues(crypto: crypto, fiat: fiat)
    }

    func setFiat(_ fiat: Decimal?) {
        let crypto: Decimal?
        if let fiat,
           let currencyId,
           let convertedCrypto = BalanceConverter().convertFromFiat(value: fiat, to: currencyId)?.rounded(scale: amountFractionDigits) {
            crypto = convertedCrypto
        } else {
            crypto = nil
        }

        setCryptoFiatValues(crypto: crypto, fiat: fiat)
    }

    private func setCryptoFiatValues(crypto: Decimal?, fiat: Decimal?) {
        _crypto.send(crypto)
        _fiat.send(fiat)

        let balanceFormatter = BalanceFormatter()
        _cryptoFormatted.send(balanceFormatter.formatCryptoBalance(crypto, currencyCode: currencyCode))
        _fiatFormatted.send(balanceFormatter.formatFiatBalance(fiat))
    }
}

extension CryptoFiatAmount: Equatable {
    static func == (left: CryptoFiatAmount, right: CryptoFiatAmount) -> Bool {
        left.crypto == right.crypto && left.fiat == right.fiat
    }
}
