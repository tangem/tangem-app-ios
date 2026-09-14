//
//  RegisterUserWalletError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum RegisterUserWalletError: Error {
    case obtainNonceFailed(ObtainUserWalletRegistrationNonceError)
    case prepareFailed(PrepareUserWalletRegistrationError)
    case submitFailed(SubmitUserWalletRegistrationError)
}
