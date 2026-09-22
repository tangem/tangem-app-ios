//
//  ObtainUserWalletRegistrationNonceError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum ObtainUserWalletRegistrationNonceError: Error {
    case deviceRegistrationFailure(RegisterDeviceError)
    case deviceKeyFailure(DeviceKeyManagerError)
    case clientFailure(UserWalletRegistrationClientError)
    case nonceDecryptionFailure(NonceDecryptorError)
    case invalidDecryptedNonceEncoding
}
