//
//  ObtainRecoveryNonceError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum ObtainRecoveryNonceError: Error {
    case deviceRegistrationFailure(RegisterDeviceError)
    case deviceKeyFailure(DeviceKeyManagerError)
    case clientFailure(UserWalletRecoveryClientError)
    case nonceDecryptionFailure(NonceDecryptorError)
}
