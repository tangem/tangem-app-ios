//
//  SafeGasToken.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemFoundation

/// What the Safe refunds the relayer in. The coin is priced straight from the network; a token needs the rate to turn
/// the network's price per gas into the token's smallest units per gas.
public enum SafeGasToken: Hashable {
    public static let coinGasTokenRawValue = "0x0000000000000000000000000000000000000000"

    case coin(Blockchain)
    case token(Token, blockchain: Blockchain, nativeToTokenRate: Decimal)

    /// The `gasToken` field of a `SafeTx`; the coin is `address(0)`.
    public var address: String {
        switch self {
        case .coin: SafeGasToken.coinGasTokenRawValue
        case .token(let token, _, _): token.contractAddress
        }
    }

    public var blockchain: Blockchain {
        switch self {
        case .coin(let blockchain): blockchain
        case .token(_, let blockchain, _): blockchain
        }
    }
}

// MARK: - Pricing

extension SafeGasToken {
    /// The network prices gas in the coin's smallest units; a token needs the same price in its own smallest units. It
    /// is rounded up because the refund is an integer per unit of gas, and a relayer paid in a coarse token must never
    /// come out short.
    func gasPrice(fromCoinGasPrice coinGasPrice: BigUInt) -> BigUInt {
        switch self {
        case .coin:
            return coinGasPrice
        case .token(let token, let blockchain, let nativeToTokenRate):
            let coinPrice = coinGasPrice.decimal ?? 0
            let tokenPrice = coinPrice * nativeToTokenRate * token.decimalValue / blockchain.decimalValue
            let decimalPrice = tokenPrice.rounded(roundingMode: .up)

            return BigUInt(decimal: decimalPrice) ?? 0
        }
    }

    func amount(value: Decimal) -> Amount {
        switch self {
        case .coin(let blockchain): Amount(with: blockchain, type: .coin, value: value)
        case .token(let token, _, _): Amount(with: token, value: value)
        }
    }
}
