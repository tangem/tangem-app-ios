//
//  XPUBAddressesWalletManagerProvider.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol XPUBAddressesWalletManagerProvider {
    func compoundTransactionIfNeeded() throws -> (amount: Amount, destination: String)?
    func updateToXpubKey(xpubKey: Wallet.PublicKey.XPUBKey) throws
    func updateToPlainKey() throws
}

public enum XPUBAddressesWalletManagerProviderError: LocalizedError {
    case balanceNotFound
    case plainHDKeyNotFound
    case xpubHDKeyNotFound

    public var errorDescription: String? {
        switch self {
        case .balanceNotFound: "Balance not found."
        case .plainHDKeyNotFound: "Plain HD key not found."
        case .xpubHDKeyNotFound: "XPUB HD key not found."
        }
    }
}
