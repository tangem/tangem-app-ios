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

    init(crypto: Decimal?, fiat: Decimal?) {
        _crypto.send(crypto)
        _fiat.send(fiat)
    }

    init(crypto: Decimal?) {
        _crypto.send(crypto)
        if let crypto {
            _fiat.send(crypto)
        } else {
            _fiat.send(nil)
        }
    }

    init(fiat: Decimal?) {
        _fiat.send(fiat)
        if let fiat {
            _crypto.send(fiat * 10)
        } else {
            _crypto.send(nil)
        }
    }

    func setCrypto(_ crypto: Decimal?) {
        let fiat: Decimal?
        if let crypto {
            fiat = crypto / 10
        } else {
            fiat = nil
        }
        _crypto.send(crypto)
        _fiat.send(fiat)
    }

    func setFiat(_ fiat: Decimal?) {
        let crypto: Decimal?
        if let fiat {
            crypto = fiat * 10
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
