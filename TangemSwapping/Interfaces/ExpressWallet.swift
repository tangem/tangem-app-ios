//
//  ExpressWallet.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressWallet {
    var currency: ExpressCurrency { get }
    var address: String { get }
}

public extension ExpressWallet {
    var contractAddress: String {
        currency.contractAddress
    }

    var network: String {
        currency.network
    }

    var isToken: Bool {
        contractAddress != ExpressConstants.coinContractAddress
    }
}
