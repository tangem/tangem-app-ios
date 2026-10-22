//
//  TangemProblemDetailError+MCP.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemNetworkUtils

extension TangemProblemDetailError {
    static let sessionRequestNotFound = TangemProblemDetailError(
        httpStatusCode: 404,
        message: "No pending session request answers this state",
        code: nil
    )
}
