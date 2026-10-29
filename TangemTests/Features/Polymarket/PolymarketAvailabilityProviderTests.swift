//
//  PolymarketAvailabilityProviderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("Polymarket availability")
struct PolymarketAvailabilityProviderTests {
    @Test("The feature opens only with the wallet enrolled in the experiment", arguments: [
        (ExperimentFeatureVariantKey.on, true),
        (nil, false),
        (.control, false),
    ] as [(ExperimentFeatureVariantKey?, Bool)])
    func featureNeedsExperiment(variant: ExperimentFeatureVariantKey?, isAvailable: Bool) {
        let sut = makeSUT(variant: variant)

        #expect(sut.isAvailable == isAvailable)
    }

    @Test("A variant cached by an earlier session or another wallet does not open the feature")
    func cachedVariantDoesNotOpen() {
        let experimentService = ExperimentServiceStub(storedVariant: ExperimentFeatureVariantKey.on.rawValue, isFetched: false)
        let sut = CommonPolymarketAvailabilityProvider(experimentService: experimentService)

        #expect(!sut.isAvailable)
    }

    @Test("Switching wallets closes the feature until the new wallet's variants arrive")
    func walletSwitchWaitsForFreshVariants() {
        let experimentService = ExperimentServiceStub(storedVariant: .on)
        let sut = CommonPolymarketAvailabilityProvider(experimentService: experimentService)
        let values = OSAllocatedUnfairLock<[Bool]>(initialState: [])

        let cancellable = sut.isAvailablePublisher(hasAccount: { false }).sink { value in values.withLock { $0.append(value) } }

        experimentService.startFetching()
        experimentService.fetch(variant: .on)

        #expect(values.withLock { $0 } == [true, false, true])

        cancellable.cancel()
    }

    @Test("A wallet that already has an account keeps the feature without the experiment")
    func walletWithAnAccountKeepsTheFeature() {
        let sut = makeSUT(variant: nil)

        #expect(sut.isAvailable(hasAccount: { true }))
    }

    @Test("Availability follows the experiment once its variants arrive")
    func availabilityFollowsFetchedVariants() {
        let experimentService = ExperimentServiceStub(storedVariant: nil)
        let sut = CommonPolymarketAvailabilityProvider(experimentService: experimentService)
        let values = OSAllocatedUnfairLock<[Bool]>(initialState: [])

        let cancellable = sut.isAvailablePublisher(hasAccount: { false }).sink { value in values.withLock { $0.append(value) } }

        experimentService.fetch(variant: .on)
        experimentService.fetch(variant: .on)
        experimentService.fetch(variant: nil)

        #expect(values.withLock { $0 } == [false, true, false])

        cancellable.cancel()
    }

    @Test("A wallet opens the feature once its account appears, with the experiment off")
    func accountAppearingOpensTheFeature() {
        let presenceChanges = PassthroughSubject<Void, Never>()
        let hasAccount = OSAllocatedUnfairLock(initialState: false)
        let sut = CommonPolymarketAvailabilityProvider(
            experimentService: ExperimentServiceStub(storedVariant: .control),
            accountPresenceChangesPublisher: presenceChanges.eraseToAnyPublisher()
        )
        let values = OSAllocatedUnfairLock<[Bool]>(initialState: [])

        let cancellable = sut
            .isAvailablePublisher(hasAccount: { hasAccount.withLock { $0 } })
            .sink { value in values.withLock { $0.append(value) } }

        hasAccount.withLock { $0 = true }
        presenceChanges.send(())

        #expect(values.withLock { $0 } == [false, true])

        cancellable.cancel()
    }
}

// MARK: - Fixtures

private extension PolymarketAvailabilityProviderTests {
    func makeSUT(variant: ExperimentFeatureVariantKey?) -> CommonPolymarketAvailabilityProvider {
        CommonPolymarketAvailabilityProvider(experimentService: ExperimentServiceStub(storedVariant: variant))
    }
}
