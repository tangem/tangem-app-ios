//
//  UserWalletRegistrationRequest.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import struct TangemFoundation.UserWalletId

/// The fully assembled, signed payload for `POST /mobile/wallet/register`,
/// produced by ``PrepareUserWalletRegistrationUseCase`` and consumed by ``SubmitUserWalletRegistrationUseCase``.
public struct UserWalletRegistrationRequest: Sendable {
    let id: UserWalletId
    let walletAttestation: UserWalletAttestation
    let decryptedNonce: String
    let appAttestationToken: Data?
    let metadata: DeviceMetadata
}
