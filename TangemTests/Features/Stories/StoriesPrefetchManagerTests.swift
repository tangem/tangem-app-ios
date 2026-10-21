//
//  StoriesPrefetchManagerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
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
        await withExperiment(variant: .control) { stub, _ in
            stub.finishWalletFetch(for: .mobileWallet)

            #expect(await !HardwareUpgradeStoriesResolver().shouldPrefetchStories())
        }
    }

    @Test(
        "An experiment with no stored variant prefetches nothing",
        .enabled(if: Self.areReleaseGatesOpen)
    )
    func unresolvedExperimentPrefetchesNothing() async {
        await withExperiment(variant: nil) { stub, _ in
            stub.finishWalletFetch(for: .mobileWallet)

            #expect(await !HardwareUpgradeStoriesResolver().shouldPrefetchStories())
        }
    }

    @Test(
        "The treatment arm prefetches the upgrade promo it will be shown",
        .enabled(if: Self.areReleaseGatesOpen)
    )
    func treatmentArmPrefetchesTheUpgradeStory() async {
        await withExperiment(variant: .treatment) { stub, _ in
            stub.finishWalletFetch(for: .mobileWallet)

            #expect(await HardwareUpgradeStoriesResolver().shouldPrefetchStories())
        }
    }

    @Test(
        "The prefetch decision reads the arm without recording an exposure",
        .enabled(if: Self.areReleaseGatesOpen)
    )
    func prefetchDecisionRecordsNoExposure() async {
        await withExperiment(variant: .treatment) { stub, _ in
            stub.finishWalletFetch(for: .mobileWallet)

            _ = await HardwareUpgradeStoriesResolver().shouldPrefetchStories()

            #expect(stub.invokedMethods.contains(.isOnWithoutExposure))
            #expect(!stub.invokedMethods.contains(.isOn))
        }
    }

    @Test(
        "The prefetch decision waits for the wallet's experiments before reading the arm",
        .enabled(if: Self.areReleaseGatesOpen),
        .timeLimit(.minutes(1))
    )
    func prefetchDecisionWaitsForWalletExperiments() async {
        await withExperiment(variant: .treatment) { stub, _ in
            let decision = Task { await HardwareUpgradeStoriesResolver().shouldPrefetchStories() }

            try? await Task.sleep(for: .milliseconds(200))
            #expect(!stub.invokedMethods.contains(.isOnWithoutExposure))

            stub.finishWalletFetch(for: .mobileWallet)

            #expect(await decision.value)
        }
    }

    @Test("App start keeps warming the legacy swap and yield stories")
    func appStartWarmsLegacyStories() {
        let ids = StoriesPrefetchManager.Step.appStart.legacyStories.map(\.id)

        #expect(ids == [.swap, .yieldFirstActivationAPYBoost])
    }

    @Test(
        "App start prefetches the upgrade story for the treatment arm only",
        .enabled(if: Self.areReleaseGatesOpen),
        arguments: [
            (ExperimentFeatureVariantKey.treatment, [StoriesV2StoryID.hardwareUpgrade]),
            (.control, []),
        ]
    )
    func appStartPrefetchesTheUpgradeStoryForTreatmentOnly(
        variant: ExperimentFeatureVariantKey,
        expected: [StoriesV2StoryID]
    ) async {
        await withExperiment(variant: variant) { stub, _ in
            stub.finishWalletFetch(for: .mobileWallet)

            #expect(await StoriesPrefetchManager().storiesToPrefetch(for: .appStart) == expected)
        }
    }

    @Test(
        "A card wallet's experiments fetch leaves the decision to the mobile wallet's one",
        .enabled(if: Self.areReleaseGatesOpen),
        .timeLimit(.minutes(1))
    )
    func cardWalletFetchWaitsForMobileWalletFetch() async {
        await withExperiment(variant: .treatment, walletProductTypes: [.wallet, .mobileWallet]) { stub, _ in
            let decision = Task { await HardwareUpgradeStoriesResolver().shouldPrefetchStories() }

            stub.finishWalletFetch(for: .wallet)
            try? await Task.sleep(for: .milliseconds(200))
            #expect(stub.invokedMethods.isEmpty)

            stub.finishWalletFetch(for: .mobileWallet)

            #expect(await decision.value)
        }
    }

    @Test(
        "A mobile wallet added later still gets the upgrade story prefetched",
        .enabled(if: Self.areReleaseGatesOpen),
        .timeLimit(.minutes(1))
    )
    func mobileWalletAddedLaterGetsTheStoryPrefetched() async {
        await withExperiment(variant: .treatment, walletProductTypes: [.wallet]) { stub, repository in
            let decision = Task { await HardwareUpgradeStoriesResolver().shouldPrefetchStories() }

            stub.finishWalletFetch(for: .wallet)
            try? await Task.sleep(for: .milliseconds(200))
            #expect(stub.invokedMethods.isEmpty)

            repository.models.append(ProductTypeWalletModelStub(productType: .mobileWallet))
            stub.finishWalletFetch(for: .mobileWallet)

            #expect(await decision.value)
        }
    }

    @Test(
        "Without a mobile wallet the upgrade story is not shown and no exposure is recorded",
        .enabled(if: Self.areReleaseGatesOpen)
    )
    func noMobileWalletShowsNothing() async {
        await withExperiment(variant: .treatment, walletProductTypes: [.wallet]) { stub, _ in
            #expect(!HardwareUpgradeStoriesResolver().shouldShowStories())
            #expect(stub.invokedMethods.isEmpty)
        }
    }

    @Test(
        "One mobile wallet among card wallets is enough to show the upgrade story",
        .enabled(if: Self.areReleaseGatesOpen)
    )
    func oneMobileWalletShowsTheStory() async {
        await withExperiment(variant: .treatment, walletProductTypes: [.wallet, .mobileWallet]) { stub, _ in
            #expect(HardwareUpgradeStoriesResolver().shouldShowStories())
            #expect(stub.invokedMethods == [.isOn])
        }
    }

    // MARK: - Helpers

    private static var areReleaseGatesOpen: Bool {
        FeatureProvider.isAvailable(.hardwareUpgradeStories)
    }

    private func withExperiment(
        variant: ExperimentFeatureVariantKey?,
        walletProductTypes: [Analytics.ProductType] = [.mobileWallet],
        _ operation: (StubExperimentService, FakeUserWalletRepository) async -> Void
    ) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousExperimentService = InjectedValues[\.experimentService]
            let previousUserWalletRepository = InjectedValues[\.userWalletRepository]
            let stub = StubExperimentService(storedVariant: variant)
            let repository = FakeUserWalletRepository(models: walletProductTypes.map(ProductTypeWalletModelStub.init))
            InjectedValues[\.experimentService] = stub
            InjectedValues[\.userWalletRepository] = repository
            defer {
                InjectedValues[\.experimentService] = previousExperimentService
                InjectedValues[\.userWalletRepository] = previousUserWalletRepository
            }
            await operation(stub, repository)
        }
    }
}

// MARK: - Stubs

private final class ProductTypeWalletModelStub: UserWalletModelMock {
    private let productType: Analytics.ProductType

    init(productType: Analytics.ProductType) {
        self.productType = productType
    }

    static func userWalletId(for productType: Analytics.ProductType) -> UserWalletId {
        UserWalletId(value: Data(productType.rawValue.utf8))
    }

    override var userWalletId: UserWalletId { Self.userWalletId(for: productType) }
    override var config: UserWalletConfig { UserWalletConfigStub(productType: productType) }
}

private final class StubExperimentService: ExperimentService {
    enum Method: Equatable {
        case isOn
        case isOnWithoutExposure
    }

    let storedVariant: ExperimentFeatureVariantKey?

    private let recordedMethods = OSAllocatedUnfairLock<[Method]>(initialState: [])
    private let fetchedUserWalletIdsSubject = CurrentValueSubject<Set<UserWalletId>, Never>([])

    init(storedVariant: ExperimentFeatureVariantKey?) {
        self.storedVariant = storedVariant
    }

    var invokedMethods: [Method] { recordedMethods.withLock { $0 } }

    func finishWalletFetch(for productType: Analytics.ProductType) {
        let userWalletId = ProductTypeWalletModelStub.userWalletId(for: productType)
        fetchedUserWalletIdsSubject.send(fetchedUserWalletIdsSubject.value.union([userWalletId]))
    }

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

    func waitForVariants(ofWalletMatching isMatching: @escaping (UserWalletId) -> Bool) async -> Bool {
        let fetched = try? await fetchedUserWalletIdsSubject
            .first { $0.contains(where: isMatching) }
            .async()

        return fetched != nil
    }
}
