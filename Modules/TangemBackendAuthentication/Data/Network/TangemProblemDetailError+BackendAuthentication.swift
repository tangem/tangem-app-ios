//
//  TangemProblemDetailError+BackendAuthentication.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemNetworkUtils

extension TangemProblemDetailError {
    static let deviceAlreadyRegistered = TangemProblemDetailError(
        httpStatusCode: 409,
        message: "Device already registered",
        code: nil
    )

    static let deviceNotFound = TangemProblemDetailError(
        httpStatusCode: 404,
        message: "Device not found",
        code: nil
    )

    static let walletAlreadyRegistered = TangemProblemDetailError(
        httpStatusCode: 400,
        message: "Wallet is already registered for this device",
        code: nil
    )

    static let walletNotRegistered = TangemProblemDetailError(
        httpStatusCode: 404,
        message: "Wallet is not registered for this device",
        code: nil
    )
}
