//
//  TangemPayAuthorizationTokensHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public protocol TangemPayAuthorizationTokensHandler: AnyObject {
    var accessTokenExpired: Bool { get }
    var refreshTokenExpired: Bool { get }
    var authorizationHeader: String? { get }

    var authorizationTokensSaver: TangemPayAuthorizationTokensSaver? { get set }

    func saveTokens(tokens: TangemPayAuthorizationTokens) throws
    func refreshTokens() async throws
}
