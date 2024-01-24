//
//  CryptoFiatAmount.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CryptoFiatAmount: Equatable {
    var crypto: Decimal? { _crypto.value }
    var fiat: Decimal? { _fiat.value }

    var cryptoPublisher: AnyPublisher<Decimal?, Never> {
        _crypto.eraseToAnyPublisher()
    }

    var fiatPublisher: AnyPublisher<Decimal?, Never> {
        _fiat.eraseToAnyPublisher()
    }

    private var _crypto = CurrentValueSubject<Decimal?, Never>(nil)
    private var _fiat = CurrentValueSubject<Decimal?, Never>(nil)

//    private let rate: Decimal = 10.001
    private let currencyId: String?

//    init(currencyId: String?, crypto: Decimal?, fiat: Decimal?) {
    ////        BalanceConverter().convertToFiat(value: <#T##Decimal#>, from: <#T##String#>)
//
//        self.currencyId = currencyId
//        _crypto.send(crypto)
//        _fiat.send(fiat)
//    }

    init(currencyId: String?) {
//        _crypto.send(crypto)
        self.currencyId = currencyId
//        if let crypto,
//           let currencyId,
//           let fiat = BalanceConverter().convertToFiat(value: crypto, from: currencyId) {
//            _fiat.send(crypto)
//        } else {
//            _fiat.send(nil)
//        }
    }

//    init(currencyId: String?, fiat: Decimal?) {
//        self.currencyId = currencyId
//        _fiat.send(fiat)
//        if let fiat {
//            _crypto.send(fiat * rate)
//        } else {
//            _crypto.send(nil)
//        }
//    }

    func setCrypto(_ crypto: Decimal?) {
        let newFiat: Decimal?
        if let crypto,
           let currencyId,
           let fiat = BalanceConverter().convertToFiat(value: crypto, from: currencyId) {
            newFiat = fiat
        } else {
            newFiat = nil
        }
        _crypto.send(crypto)
        _fiat.send(newFiat)
    }

    func setFiat(_ fiat: Decimal?) {
        let crypto: Decimal?
        if let fiat,
           let currencyId,
           let convertedCrypto = BalanceConverter().convertFromFiat(value: fiat, to: currencyId) {
            crypto = convertedCrypto
        } else {
            crypto = nil
        }
        _crypto.send(crypto)
        _fiat.send(fiat)
    }

//    func update(crypto: Decimal?, fiat: Decimal?) {
//        self.crypto.send(crypto)
//        self.fiat.send(fiat)
//    }

    static func == (left: CryptoFiatAmount, right: CryptoFiatAmount) -> Bool {
        left.crypto == right.crypto && left.fiat == right.fiat
    }
}
