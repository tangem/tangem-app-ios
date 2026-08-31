//
//  RegisterDeviceError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum RegisterDeviceError: Error {
    case clientFailure(DeviceRegistrationClientError)
    case nonceDecryptionFailure(NonceDecryptorError)
    case deviceKeyFailure(DeviceKeyManagerError)
    case repositoryFailure(SessionTokensRepositoryError)
}
