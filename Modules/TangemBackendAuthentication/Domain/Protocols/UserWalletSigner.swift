//
//  UserWalletSigner.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct Foundation.Data

public protocol UserWalletSigner: Sendable {
    func attest(challenge: Data) async throws(UserWalletSignerError) -> UserWalletAttestation
}
