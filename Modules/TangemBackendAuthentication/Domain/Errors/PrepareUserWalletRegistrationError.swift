//
//  PrepareUserWalletRegistrationError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum PrepareUserWalletRegistrationError: Error {
    case signerFailure(UserWalletRegistrationSignerError)
}
