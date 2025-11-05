//
//  TangemPayUtilities.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemSdk

public enum TangemPayUtilities {}

public extension TangemPayUtilities {
    static var mandatoryCurve: EllipticCurve {
        .secp256k1
    }

    static var blockchain: Blockchain {
        .polygon(testnet: false)
    }

    static var derivationPath: DerivationPath {
        try! DerivationPath(rawPath: "m/44'/60'/999999'/0/0")
    }

    static func makeAddress(using walletPublicKey: Wallet.PublicKey) throws -> String {
        try AddressServiceFactory(blockchain: TangemPayUtilities.blockchain)
            .makeAddressService()
            .makeAddress(for: walletPublicKey, with: .default)
            .value
    }

    static func makeCustomerWalletSigningRequestMessage(nonce: String) -> String {
        // This message format is defined by backend
        "Tangem Pay wants to sign in with your account. Nonce: \(nonce)"
    }

    static func makeEIP191Message(content: String) -> String {
        "\u{19}Ethereum Signed Message:\n\(content.count)\(content)"
    }
}
