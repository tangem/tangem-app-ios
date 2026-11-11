//
//  PolymarketFastTradingPauseToggleTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemPolymarket
import TangemUI
@testable import Tangem

@MainActor
@Suite("Polymarket fast trading: pause behind its own toggle")
struct PolymarketFastTradingPauseToggleTests {
    @Test(
        "This device and other devices offer Pause only while its toggle is on",
        arguments: zip(
            [true, false],
            [
                [PolymarketFastTradingDevice.Trailing.menu([.pause, .revoke]), .menu([.pause, .revoke])],
                [.menu([.revoke]), .menu([.revoke])],
            ]
        )
    )
    func pauseFollowsItsToggle(_ isPauseAvailable: Bool, _ trailing: [PolymarketFastTradingDevice.Trailing]) {
        let sut = Self.makeSUT(keys: [Fixture.key(.local), Fixture.key(.otherDevice)], isPauseAvailable: isPauseAvailable)

        #expect(Self.trailing(of: sut) == trailing)
    }

    @Test("A key paused already, on this device or another one, keeps Resume and Revoke with the pause toggle off")
    func pausedKeyKeepsResumeWithoutTheToggle() {
        let sut = Self.makeSUT(
            keys: [Fixture.key(.local, isEnabled: false), Fixture.key(.otherDevice, isEnabled: false)],
            isPauseAvailable: false
        )

        #expect(Self.trailing(of: sut) == [.menu([.resume, .revoke]), .menu([.resume, .revoke])])
    }

    @Test("With the pause toggle off the settings screen ignores a pause request and still resumes a paused key")
    func pauseRequestIsIgnoredWithoutTheToggle() {
        let sut = Self.makeSUT(keys: [Fixture.key(.otherDevice)], isPauseAvailable: false)
        let device = PolymarketFastTradingDevice(
            source: .sessionKey(address: Fixture.Owner.otherDevice.address),
            name: Fixture.deviceName,
            owner: .otherDevice,
            state: .active(until: Fixture.validUntil)
        )

        sut.handleViewAction(.device(.pause, device))

        #expect(!sut.isProcessing)

        sut.handleViewAction(.device(.resume, device))

        #expect(sut.isProcessing)
    }
}

// MARK: - Helpers

private typealias Fixture = PolymarketSessionKeyFixtures

private extension PolymarketFastTradingPauseToggleTests {
    static func makeSUT(keys: [PolymarketSessionKey], isPauseAvailable: Bool) -> PolymarketFastTradingViewModel {
        let assessment = Fixture.assess(keys: keys, signers: keys.map(PolymarketSessionSigner.matching))

        return PolymarketFastTradingViewModel(
            service: FastTradingOperatingStub(state: .loaded(assessment)),
            signingButtonType: .requiredNFCInteraction,
            thisDeviceName: Fixture.deviceName,
            isPauseAvailable: isPauseAvailable,
            onClose: {}
        )
    }

    static func trailing(of sut: PolymarketFastTradingViewModel) -> [PolymarketFastTradingDevice.Trailing] {
        guard case .device(let thisDevice) = sut.thisDevice else {
            Issue.record("This device has no row: \(sut.thisDevice)")
            return []
        }

        return ([thisDevice] + sut.otherDevices).map(sut.trailing(for:))
    }
}

// MARK: - Stubs

@MainActor
private final class FastTradingOperatingStub: PolymarketFastTradingOperating {
    let state: PolymarketFastTradingState

    init(state: PolymarketFastTradingState) {
        self.state = state
    }

    var statePublisher: AnyPublisher<PolymarketFastTradingState, Never> {
        Just(state).eraseToAnyPublisher()
    }

    func refresh() async {}

    func authorize(_ authorization: PolymarketFastTradingAuthorization) async throws {}

    func authorize(presigned batch: PolymarketRelayedBatch, grant: PolymarketSessionKeyGrant) async throws {}

    func revoke(sessionKeyAddress: String) async throws {}

    func setEnabled(_ isEnabled: Bool, sessionKeyAddress: String) async throws {}
}
