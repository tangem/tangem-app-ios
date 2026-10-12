//
//  AttestUserWalletError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum AttestUserWalletError: Error {
    case signerFailure(UserWalletRegistrationSignerError)
}
