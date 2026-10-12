//
//  RegisterUserWalletError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum RegisterUserWalletError: Error {
    case obtainNonceFailure(ObtainUserWalletRegistrationNonceError)
    case attestUserWalletFailure(AttestUserWalletError)
    case submitFailure(SubmitUserWalletRegistrationError)
}
