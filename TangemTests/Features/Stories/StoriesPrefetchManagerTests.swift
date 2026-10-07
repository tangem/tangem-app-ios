//
//  StoriesPrefetchManagerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Testing
import Experiment
import TangemFoundation
import TangemStories
@testable import Tangem

@Suite("StoriesPrefetchManagerTests", .serialized)
struct StoriesPrefetchManagerTests {
    @Test(
        "The control arm prefetches nothing, so it never downloads the promo videos",
        .enabled(if: Self.areReleaseGatesOpen)
    )
    func controlArmPrefetchesNothing() async {
        await withExperiment(variant: .control) { _ in
            #expect(StoriesPrefetchManager().storiesToPrefetch(for: .appStart).isEmpty)
        }
    }

    @Test(
        "An experiment with no stored variant prefetches nothing",
        .enabled(if: Self.areReleaseGatesOpen)
    )
    func unresolvedExperimentPrefetchesNothing() async {
        await withExperiment(variant: nil) { _ in
            #expect(StoriesPrefetchManager().storiesToPrefetch(for: .appStart).isEmpty)
        }
    }

    @Test(
        "The treatment arm prefetches the upgrade promo it will be shown",
        .enabled(if: Self.areReleaseGatesOpen)
    )
    func treatmentArmPrefetchesTheUpgradeStory() async {
        await withExperiment(variant: .treatment) { _ in
            #expect(StoriesPrefetchManager().storiesToPrefetch(for: .appStart) == [.hardwareUpgrade])
        }
    }

    @Test(
        "The prefetch selection reads the arm without recording an exposure",
        .enabled(if: Self.areReleaseGatesOpen)
    )
    func prefetchSelectionRecordsNoExposure() async {
        await withExperiment(variant: .treatment) { stub in
            _ = StoriesPrefetchManager().storiesToPrefetch(for: .appStart)

            #expect(stub.invokedMethods.contains(.isOnWithoutExposure))
            #expect(!stub.invokedMethods.contains(.isOn))
        }
    }

    @Test("App start keeps warming the legacy swap and yield stories")
    func appStartWarmsLegacyStories() {
        let ids = StoriesPrefetchManager.Step.appStart.legacyStories.map(\.id)

        #expect(ids == [.swap, .yieldFirstActivationAPYBoost])
    }

    // MARK: - Helpers

    private static var areReleaseGatesOpen: Bool {
        FeatureProvider.isAvailable(.storiesV2) && FeatureProvider.isAvailable(.hardwareUpgradeStories)
    }

    private func withExperiment(variant: ExperimentFeatureVariantKey?, _ operation: (StubExperimentService) -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let previous = InjectedValues[\.experimentService]
            let stub = StubExperimentService(storedVariant: variant)
            InjectedValues[\.experimentService] = stub
            defer { InjectedValues[\.experimentService] = previous }
            operation(stub)
        }
    }
}

// MARK: - Stub

private final class StubExperimentService: ExperimentService {
    enum Method: Equatable {
        case isOn
        case isOnWithoutExposure
    }

    let storedVariant: ExperimentFeatureVariantKey?

    private let recordedMethods = OSAllocatedUnfairLock<[Method]>(initialState: [])

    init(storedVariant: ExperimentFeatureVariantKey?) {
        self.storedVariant = storedVariant
    }

    var invokedMethods: [Method] { recordedMethods.withLock { $0 } }

    var variantsPublisher: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }

    func configure() {}

    func variant(_ key: ExperimentFeatureFlagKey) -> Variant? {
        storedVariant.map { Variant($0.rawValue) }
    }

    func isOn(_ key: ExperimentFeatureFlagKey, variant: ExperimentFeatureVariantKey) -> Bool {
        recordedMethods.withLock { $0.append(.isOn) }
        return storedVariant == variant
    }

    func isOnWithoutExposure(_ key: ExperimentFeatureFlagKey, variant: ExperimentFeatureVariantKey) -> Bool {
        recordedMethods.withLock { $0.append(.isOnWithoutExposure) }
        return storedVariant == variant
    }
}
