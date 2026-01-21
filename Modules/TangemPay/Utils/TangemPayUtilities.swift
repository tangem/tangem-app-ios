//
//  TangemPayUtilities.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import CryptoSwift
import Foundation
import TangemSdk

public enum TangemPayUtilities {}

public extension TangemPayUtilities {
    static var mandatoryCurve: EllipticCurve {
        .secp256k1
    }

    static var derivationPath: DerivationPath {
        try! DerivationPath(rawPath: "m/44'/60'/999999'/0/0")
    }

    static func prepareForSign(challengeResponse: TangemPayGetChallengeResponse) throws -> SignRequestData {
        let signingRequestMessage = Self.makeCustomerWalletSigningRequestMessage(nonce: challengeResponse.nonce)
        let eip191Message = Self.makeEIP191Message(content: signingRequestMessage)

        guard let eip191MessageData = eip191Message.data(using: .utf8) else {
            throw Error.failedToCreateEIP191Message(content: signingRequestMessage)
        }

        let hash = eip191MessageData.sha3(.keccak256)
        return SignRequestData(message: signingRequestMessage, hash: hash)
    }

    private static func makeCustomerWalletSigningRequestMessage(nonce: String) -> String {
        // This message format is defined by backend
        "Tangem Pay wants to sign in with your account. Nonce: \(nonce)"
    }

    private static func makeEIP191Message(content: String) -> String {
        "\u{19}Ethereum Signed Message:\n\(content.count)\(content)"
    }
}

public extension TangemPayUtilities {
    struct SignRequestData {
        public let message: String
        public let hash: Data
    }

    enum Error: Swift.Error {
        case failedToCreateEIP191Message(content: String)
    }
}
