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
    @Test("The feature opens only with the toggle on and the wallet enrolled in the experiment", arguments: [
        (true, ExperimentFeatureVariantKey.on, true),
        (true, nil, false),
        (true, .control, false),
        (false, .on, false),
        (false, nil, false),
    ] as [(Bool, ExperimentFeatureVariantKey?, Bool)])
    func featureNeedsToggleAndExperiment(isToggleOn: Bool, variant: ExperimentFeatureVariantKey?, isAvailable: Bool) {
        let sut = makeSUT(isToggleOn: isToggleOn, variant: variant)

        #expect(sut.isAvailable == isAvailable)
    }

    @Test("A variant cached by an earlier session or another wallet does not open the feature")
    func cachedVariantDoesNotOpen() {
        let experimentService = ExperimentServiceStub(storedVariant: ExperimentFeatureVariantKey.on.rawValue, isFetched: false)
        let sut = CommonPolymarketAvailabilityProvider(experimentService: experimentService, isToggleOn: { true })

        #expect(!sut.isAvailable)
    }

    @Test("Switching wallets closes the feature until the new wallet's variants arrive")
    func walletSwitchWaitsForFreshVariants() {
        let experimentService = ExperimentServiceStub(storedVariant: .on)
        let sut = CommonPolymarketAvailabilityProvider(experimentService: experimentService, isToggleOn: { true })
        let values = OSAllocatedUnfairLock<[Bool]>(initialState: [])

        let cancellable = sut.isAvailablePublisher(hasAccount: { false }).sink { value in values.withLock { $0.append(value) } }

        experimentService.startFetching()
        experimentService.fetch(variant: .on)

        #expect(values.withLock { $0 } == [true, false, true])

        cancellable.cancel()
    }

    @Test("The experiment is not read while the toggle is off")
    func experimentNotReadWithToggleOff() {
        let experimentService = ExperimentServiceStub(storedVariant: .on)
        let sut = CommonPolymarketAvailabilityProvider(experimentService: experimentService, isToggleOn: { false })

        _ = sut.isAvailable

        #expect(experimentService.invokedMethods.isEmpty)
    }

    @Test("A wallet that already has an account keeps the feature without the toggle and the experiment")
    func walletWithAnAccountKeepsTheFeature() {
        let sut = makeSUT(isToggleOn: false, variant: nil)

        #expect(sut.isAvailable(hasAccount: { true }))
    }

    @Test("A wallet without an account follows the feature-wide decision", arguments: [true, false])
    func walletWithoutAnAccountFollowsTheFeature(isEnrolled: Bool) {
        let sut = makeSUT(isToggleOn: true, variant: isEnrolled ? .on : nil)

        #expect(sut.isAvailable(hasAccount: { false }) == isEnrolled)
    }

    @Test("Availability follows the experiment once its variants arrive")
    func availabilityFollowsFetchedVariants() {
        let experimentService = ExperimentServiceStub(storedVariant: nil)
        let sut = CommonPolymarketAvailabilityProvider(experimentService: experimentService, isToggleOn: { true })
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
            isToggleOn: { true },
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
    func makeSUT(isToggleOn: Bool, variant: ExperimentFeatureVariantKey?) -> CommonPolymarketAvailabilityProvider {
        CommonPolymarketAvailabilityProvider(
            experimentService: ExperimentServiceStub(storedVariant: variant),
            isToggleOn: { isToggleOn }
        )
    }
}
