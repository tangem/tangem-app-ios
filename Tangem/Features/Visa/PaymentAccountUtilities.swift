//
//  PaymentAccountUtilities.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemVisa
import TangemPay
import TangemSdk

public protocol PaymentAccountSignRequestData {
    var message: String { get }
    var hash: Data { get }
}

public protocol PaymentAccountGetChallengeResponse {
    var nonce: String { get }
    var sessionId: String { get }
}

extension TangemPayUtilities.SignRequestData: PaymentAccountSignRequestData {}
extension TangemPayGetChallengeResponse: PaymentAccountGetChallengeResponse {}

public protocol PaymentAccountUtilities {
    var derivationPath: DerivationPath { get }
    var mandatoryCurve: EllipticCurve { get }
    func makeAddress(using walletPublicKey: Wallet.PublicKey) throws -> String
    func prepareForSign(
        challengeResponse: PaymentAccountGetChallengeResponse
    ) throws -> PaymentAccountSignRequestData
}

extension PaymentAccountUtilities where Self == TangemPayAccountUtilities {
    static var tangemPay: Self { .init() }
}

extension PaymentAccountUtilities where Self == MoneriumAccountUtilities {
    static var virtualAccount: Self { .init() }
}
