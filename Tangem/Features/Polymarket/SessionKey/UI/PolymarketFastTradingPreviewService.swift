//
//  PolymarketFastTradingPreviewService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if DEBUG
import Combine
import Foundation
import TangemPolymarket

@MainActor
final class PolymarketFastTradingPreviewService: PolymarketFastTradingServicing {
    let state: PolymarketFastTradingState

    var statePublisher: AnyPublisher<PolymarketFastTradingState, Never> {
        Just(state).eraseToAnyPublisher()
    }

    func bannerPublisher(includingForeignSigners: Bool) -> AnyPublisher<PolymarketFastTradingBanner?, Never> {
        Just(PolymarketFastTradingBanner(state: state, includingForeignSigners: includingForeignSigners, isDismissed: { _ in false }))
            .eraseToAnyPublisher()
    }

    var failurePublisher: AnyPublisher<PolymarketFastTradingFailure, Never> {
        Empty().eraseToAnyPublisher()
    }

    init(sessionKeys: [PolymarketSessionKey], localKeyAddress: String? = nil, signers: [PolymarketSessionSigner]? = nil) {
        state = .loaded(PolymarketFastTradingAssessment(snapshot: PolymarketFastTradingSnapshot(
            sessionKeys: sessionKeys,
            localKeyAddress: localKeyAddress,
            deviceId: Self.thisDeviceId,
            signers: signers,
            now: Date()
        )))
    }

    func refresh() async {}

    func enable() async throws {}

    func authorize(presigned batch: PolymarketRelayedBatch, grant: PolymarketSessionKeyGrant) async throws {}

    func renew() async throws {}

    func replace(previous: PolymarketSessionKey, revokesPrevious: Bool) async throws {}

    func revoke(sessionKeyAddress: String) async throws {}

    func setEnabled(_ isEnabled: Bool, sessionKeyAddress: String) async throws {}

    func dismissBanner(_ banner: PolymarketFastTradingBanner) {}
}

extension PolymarketFastTradingPreviewService {
    static let thisDeviceId = "this-device"

    static func sessionKey(
        address: String,
        deviceName: String,
        deviceId: String = "other-device",
        status: PolymarketSessionKey.Status,
        isEnabled: Bool = true,
        validUntil: Date? = Date().addingTimeInterval(120 * 24 * 60 * 60)
    ) -> PolymarketSessionKey {
        PolymarketSessionKey(
            address: address,
            deviceId: deviceId,
            deviceName: deviceName,
            isEnabled: isEnabled,
            status: status,
            scopes: [],
            validUntil: validUntil,
            renewAfter: nil,
            authorizedAt: Date().addingTimeInterval(-24 * 60 * 60),
            createdAt: Date()
        )
    }
}
#endif
