//
//  TangemPayOfframpOrderSigner.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemPay

protocol TangemPayOfframpOrderSigning {
    func signature(for preSignature: TangemPayWithdrawPreSignature) async throws -> String
}

struct CommonTangemPayOfframpOrderSigner {
    private let signerFactory: TangemSignerFactory
    private let walletPublicKey: Wallet.PublicKey?

    init(signerFactory: TangemSignerFactory, walletPublicKey: Wallet.PublicKey?) {
        self.signerFactory = signerFactory
        self.walletPublicKey = walletPublicKey
    }
}

// MARK: - TangemPayOfframpOrderSigning

extension CommonTangemPayOfframpOrderSigner: TangemPayOfframpOrderSigning {
    func signature(for preSignature: TangemPayWithdrawPreSignature) async throws -> String {
        guard let walletPublicKey else {
            throw Error.walletPublicKeyNotFound
        }

        guard preSignature.isHashConsistent else {
            throw Error.hashMismatch
        }

        let signatureInfo = try await signerFactory
            .makeSigner()
            .sign(hash: preSignature.hash, walletPublicKey: walletPublicKey)
            .async()

        return try signatureInfo.unmarshal().hexString.addHexPrefix()
    }
}

// MARK: - Error

extension CommonTangemPayOfframpOrderSigner {
    enum Error: LocalizedError {
        case walletPublicKeyNotFound
        case hashMismatch
    }
}
