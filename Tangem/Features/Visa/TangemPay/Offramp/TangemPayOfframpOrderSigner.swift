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
import TangemVisa

protocol TangemPayOfframpOrderSigning {
    func signature(
        for preSignature: TangemPayWithdrawPreSignature,
        expecting expectation: TangemPayOfframpPreSignatureVerifier.Expectation
    ) async throws -> String
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
    func signature(
        for preSignature: TangemPayWithdrawPreSignature,
        expecting expectation: TangemPayOfframpPreSignatureVerifier.Expectation
    ) async throws -> String {
        guard let walletPublicKey else {
            throw Error.walletPublicKeyNotFound
        }

        do {
            try TangemPayOfframpPreSignatureVerifier(fiatItem: TangemPayUtilities.fiatItem)
                .verify(preSignature, against: expectation)
        } catch {
            VisaLogger.error("Tangem Pay off-ramp withdraw data does not match the order", error: error)
            throw error
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
    }
}
