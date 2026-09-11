//
//  RenewSessionTokensError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum RenewSessionTokensError: Error {
    case clientFailure(SessionAuthenticationClientError)
    case nonceDecryptionFailure(NonceDecryptorError)
    case deviceKeyFailure(DeviceKeyManagerError)
    case repositoryFailure(SessionTokensRepositoryError)
    case registrationFailure(RegisterDeviceError)
}
