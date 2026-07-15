//
//  XPUBAddressesWalletManagerProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol XPUBAddressesWalletManagerProvider {
    var hasPendingUnspentOutputs: Bool { get }

    func compoundTransactionIfNeeded() -> (amount: Amount, destination: String)?
    func updateToXpubKey(xpubKey: Wallet.PublicKey.XPUBKey) throws
    func updateToPlainKey() throws
}

public enum XPUBAddressesWalletManagerProviderError: LocalizedError {
    case plainHDKeyNotFound
    case xpubHDKeyNotFound

    public var errorDescription: String? {
        switch self {
        case .plainHDKeyNotFound: "Plain HD key not found."
        case .xpubHDKeyNotFound: "XPUB HD key not found."
        }
    }
}
