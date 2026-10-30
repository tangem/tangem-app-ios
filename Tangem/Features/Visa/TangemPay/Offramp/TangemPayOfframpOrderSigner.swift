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
    private let balancesService: any TangemPayBalancesService

    init(
        signerFactory: TangemSignerFactory,
        walletPublicKey: Wallet.PublicKey?,
        balancesService: any TangemPayBalancesService
    ) {
        self.signerFactory = signerFactory
        self.walletPublicKey = walletPublicKey
        self.balancesService = balancesService
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

        let network = balancesService.networks.first { $0.chainId == expectation.chainId }

        guard let depositAddress = network?.depositAddress else {
            throw Error.depositAddressNotFound
        }

        do {
            try TangemPayOfframpPreSignatureVerifier(fiatItem: TangemPayUtilities.fiatItem)
                .verify(preSignature, against: expectation, depositAddress: depositAddress)
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
        case depositAddressNotFound
    }
}
