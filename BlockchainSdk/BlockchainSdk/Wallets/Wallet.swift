//
//  Wallet.swift
//  blockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public enum WalletType {
    case `default`
    case nft
}

public protocol Wallet: class {
    var walletType: WalletType {get}
    var blockchain: Blockchain {get}
    var address: String {get}
    var exploreUrl: URL {get}
    var shareString: String {get}
    var allowExtract: Bool {get}
    var allowLoad: Bool {get}
    var token: Token? {get}
}
