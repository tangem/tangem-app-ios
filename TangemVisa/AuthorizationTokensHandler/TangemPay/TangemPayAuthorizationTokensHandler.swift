//
//  TangemPayAuthorizationTokensHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

public protocol TangemPayAuthorizationTokensHandler: AnyObject {
    var refreshTokenExpired: Bool { get }
    var authorizationHeader: String? { get }
    var errorEventPublisher: AnyPublisher<TangemPayApiErrorEvent, Never> { get }

    func saveTokens(tokens: TangemPayAuthorizationTokens) throws
    func prepare() async throws
}
