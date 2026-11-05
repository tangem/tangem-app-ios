//
//  SessionAuthenticationClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SessionAuthenticationClient: Sendable {
    func requestCipheredNonce(devicePublicKey: DevicePublicKey) async throws(SessionAuthenticationClientError) -> String

    func authenticate(request: SessionAuthenticationRequest) async throws(SessionAuthenticationClientError) -> SessionTokens

    /// - Parameter accessToken: The current (possibly expired) access token — this endpoint is
    ///   session-authenticated: its DPoP proof embeds this token's hash as `ath`, and it's sent
    ///   verbatim as `Authorization: DPoP <accessToken>`.
    func refresh(refreshToken: String, accessToken: String) async throws(SessionAuthenticationClientError) -> SessionTokens
}
