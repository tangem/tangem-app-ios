//
//  CommonPolymarketSessionKeyService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

final class CommonPolymarketSessionKeyService {
    private let provider: TangemProvider<PolymarketSessionKeyTarget>
    private let environment: () -> PolymarketBFFEnvironment
    private let walletId: String

    private let decoder = JSONDecoder()
    private let mapper = PolymarketMapper()

    init(
        provider: TangemProvider<PolymarketSessionKeyTarget>,
        environment: @escaping () -> PolymarketBFFEnvironment,
        walletId: String
    ) {
        self.provider = provider
        self.environment = environment
        self.walletId = walletId
    }
}

// MARK: - PolymarketSessionKeyService protocol conformance

extension CommonPolymarketSessionKeyService: PolymarketSessionKeyService {
    func sessionKeys() async throws(PolymarketSessionKeyError) -> [PolymarketSessionKey] {
        let response: PolymarketDTO.WalletStatusResponse = try await request(.sessionKeys)

        return (response.sessionKeys ?? []).map(mapper.mapSessionKey)
    }

    func authorize(
        _ authorization: PolymarketSessionKeyAuthorization
    ) async throws(PolymarketSessionKeyError) -> PolymarketSessionKey {
        let payload = PolymarketDTO.SessionKeyAuthorizationRequest(
            batch: authorization.batch,
            sessionKeyAddress: authorization.sessionKeyAddress,
            deviceId: authorization.deviceId,
            deviceName: authorization.deviceName,
            validUntil: String(Int(authorization.validUntil.timeIntervalSince1970)),
            replacesSessionKeyAddress: authorization.replacesSessionKeyAddress
        )

        let response: PolymarketDTO.SessionKey = try await request(.authorize(payload))

        return mapper.mapSessionKey(response)
    }

    func revoke(_ revocation: PolymarketSessionKeyRevocation) async throws(PolymarketSessionKeyError) -> PolymarketSessionKey {
        let payload = PolymarketDTO.SessionKeyRevocationRequest(
            batch: revocation.batch,
            sessionKeyAddress: revocation.sessionKeyAddress
        )

        let response: PolymarketDTO.SessionKey = try await request(.revoke(payload))

        return mapper.mapSessionKey(response)
    }

    func setEnabled(
        _ isEnabled: Bool,
        sessionKeyAddress: String
    ) async throws(PolymarketSessionKeyError) -> PolymarketSessionKey {
        let response: PolymarketDTO.SessionKey = try await request(
            .setEnabled(sessionKeyAddress: sessionKeyAddress, PolymarketDTO.SessionKeyEnabledRequest(enabled: isEnabled))
        )

        return mapper.mapSessionKey(response)
    }
}

// MARK: - Private implementation

private extension CommonPolymarketSessionKeyService {
    func request<T: Decodable>(_ target: PolymarketSessionKeyTarget.Target) async throws(PolymarketSessionKeyError) -> T {
        try await PolymarketRelayedRequest.perform(
            PolymarketSessionKeyTarget(environment: environment(), walletId: walletId, target: target),
            provider: provider,
            decoder: decoder,
            failure: PolymarketSessionKeyError.self
        )
    }
}
