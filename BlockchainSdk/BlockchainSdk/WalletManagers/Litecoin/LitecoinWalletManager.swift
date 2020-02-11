//
//  LitecoinWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class LitecoinWalletManager: BitcoinWalletManager {
    @available(iOS 13.0, *)
    override func getFee(amount: Amount, source: String, destination: String) -> AnyPublisher<[Amount], Error> {
        let fee = Amount(with: .litecoin, address: source, value: Decimal(string: "0.00001"))
        return Just([fee])
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
