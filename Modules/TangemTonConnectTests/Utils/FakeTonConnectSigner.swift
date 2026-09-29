//
//  FakeTonConnectSigner.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation
@testable import TangemTonConnect

/// In-memory Ed25519 signer standing in for the card. Records every digest it was asked to sign.
final class FakeTonConnectSigner: TonConnectSigner, @unchecked Sendable {
    let privateKey: Curve25519.Signing.PrivateKey
    private(set) var signedDigests: [Data] = []

    init(privateKey: Curve25519.Signing.PrivateKey = Curve25519.Signing.PrivateKey()) {
        self.privateKey = privateKey
    }

    var publicKey: Data { privateKey.publicKey.rawRepresentation }

    func sign(digest: Data) async throws -> Data {
        signedDigests.append(digest)
        return try privateKey.signature(for: digest)
    }

    func verify(signature: Data, digest: Data) -> Bool {
        privateKey.publicKey.isValidSignature(signature, for: digest)
    }
}

/// Signer that returns a malformed signature.
struct BrokenTonConnectSigner: TonConnectSigner {
    func sign(digest: Data) async throws -> Data {
        Data(repeating: 0, count: 10)
    }
}

extension Data {
    init(hex: String) {
        self = Data(tonConnectHex: hex)!
    }
}
