//
//  PaymentAccountUtilities+Conformance.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemPay
import TangemSdk

struct TangemPayAccountUtilities: PaymentAccountUtilities {
    var derivationPath: DerivationPath {
        TangemPayUtilities.derivationPath
    }

    var mandatoryCurve: EllipticCurve {
        TangemPayUtilities.mandatoryCurve
    }

    func makeAddress(using walletPublicKey: Wallet.PublicKey) throws -> String {
        try TangemPayUtilities.makeAddress(using: walletPublicKey)
    }

    func prepareForSign(
        challengeResponse: PaymentAccountGetChallengeResponse
    ) throws -> PaymentAccountSignRequestData {
        try TangemPayUtilities._prepareForSign(challengeResponse: challengeResponse)
    }
}

struct MoneriumAccountUtilities: PaymentAccountUtilities {
    var derivationPath: DerivationPath {
        VirtualAccountUtilities.derivationPath
    }

    var mandatoryCurve: EllipticCurve {
        VirtualAccountUtilities.mandatoryCurve
    }

    func makeAddress(using walletPublicKey: Wallet.PublicKey) throws -> String {
        try VirtualAccountUtilities.makeAddress(using: walletPublicKey)
    }

    func prepareForSign(
        challengeResponse: PaymentAccountGetChallengeResponse
    ) throws -> PaymentAccountSignRequestData {
        try VirtualAccountUtilities._prepareForSign(challengeResponse: challengeResponse)
    }
}
