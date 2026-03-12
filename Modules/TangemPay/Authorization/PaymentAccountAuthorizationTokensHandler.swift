//
//  PaymentAccountAuthorizationTokensHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol PaymentAccountAuthorizationTokensHandler: AnyObject {
    var authorizationHeader: String? { get }

    func saveTokens(tokens: TangemPayAuthorizationTokens) throws
    func prepare() async throws(TangemPayAPIServiceError)
}
