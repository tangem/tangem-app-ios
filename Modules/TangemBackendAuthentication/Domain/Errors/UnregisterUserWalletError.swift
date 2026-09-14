//
//  UnregisterUserWalletError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum UnregisterUserWalletError: Error {
    case clientFailure(UserWalletRegistrationClientError)
    case repositoryFailure(SessionTokensRepositoryError)
}
