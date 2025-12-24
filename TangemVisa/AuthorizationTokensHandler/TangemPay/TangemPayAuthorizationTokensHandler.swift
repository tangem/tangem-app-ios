//
//  TangemPayAuthorizationTokensHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public protocol TangemPayAuthorizationTokensHandler: AnyObject {
    var tokens: TangemPayAuthorizationTokens? { get }
    var authorizationHeader: String? { get }

    func saveTokens(tokens: TangemPayAuthorizationTokens) throws
    func prepare() async throws(TangemPayAuthorizationTokensHandlerError)
}
