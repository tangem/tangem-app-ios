//
//  PromoCampaignFlowLauncherTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Testing
@testable import Tangem

@Suite("Promo campaign flow launcher")
struct PromoCampaignFlowLauncherTests {
    @Test("A flow starts for the campaign and wallet it is asked for")
    func startsFlow() {
        let (sut, factory) = makeSUT()

        sut.startFlow(campaignId: 5, userWalletId: Constants.userWalletId)

        #expect(factory.flows.map(\.startedCampaignIds) == [[5]])
        #expect(sut.isFlowActive)
    }

    @Test("A second start while a flow is up is ignored, whoever asks")
    func secondStartWhileActiveIsIgnored() {
        let (sut, factory) = makeSUT()

        sut.startFlow(campaignId: 5, userWalletId: Constants.userWalletId)
        sut.startFlow(campaignId: 5, userWalletId: Constants.userWalletId)
        sut.startFlow(campaignId: 7, userWalletId: Constants.userWalletId)

        #expect(factory.flows.count == 1)
    }

    @Test("A flow that went stale gives way to a new one")
    func staleFlowGivesWay() throws {
        let (sut, factory) = makeSUT()

        sut.startFlow(campaignId: 5, userWalletId: Constants.userWalletId)
        try #require(factory.flows.first).isStale = true
        sut.startFlow(campaignId: 7, userWalletId: Constants.userWalletId)

        #expect(factory.flows.map(\.startedCampaignIds) == [[5], [7]])
    }

    @Test("A finished flow gives way to a new one")
    func finishedFlowGivesWay() throws {
        let (sut, factory) = makeSUT()

        sut.startFlow(campaignId: 5, userWalletId: Constants.userWalletId)
        try #require(factory.flows.first).finish()

        #expect(!sut.isFlowActive)

        sut.startFlow(campaignId: 7, userWalletId: Constants.userWalletId)

        #expect(factory.flows.count == 2)
    }

    @Test("A stale flow finishing after a newer one started leaves the newer one in charge")
    func staleFlowFinishingKeepsNewerFlow() throws {
        let (sut, factory) = makeSUT()

        sut.startFlow(campaignId: 5, userWalletId: Constants.userWalletId)
        let staleFlow = try #require(factory.flows.first)
        staleFlow.isStale = true
        sut.startFlow(campaignId: 7, userWalletId: Constants.userWalletId)

        staleFlow.finish()

        #expect(sut.isFlowActive)

        sut.startFlow(campaignId: 9, userWalletId: Constants.userWalletId)

        #expect(factory.flows.count == 2)
    }
}

// MARK: - Helpers

private extension PromoCampaignFlowLauncherTests {
    enum Constants {
        static let userWalletId = UserWalletId(value: Data([0xAA]))
    }

    func makeSUT() -> (PromoCampaignFlowLauncher, PromoCampaignFlowFactorySpy) {
        let factory = PromoCampaignFlowFactorySpy()
        let sut = PromoCampaignFlowLauncher(makeFlow: factory.makeFlow)
        return (sut, factory)
    }
}

// MARK: - Stubs

private final class PromoCampaignFlowFactorySpy {
    private(set) var flows: [PromoCampaignFlowSpy] = []

    func makeFlow(onFinish: @escaping () -> Void) -> PromoCampaignFlow {
        let flow = PromoCampaignFlowSpy(onFinish: onFinish)
        flows.append(flow)
        return flow
    }
}

private final class PromoCampaignFlowSpy: PromoCampaignFlow {
    var isStale = false
    private(set) var startedCampaignIds: [Int] = []

    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func start(with options: PromoCampaignCoordinator.Options) {
        startedCampaignIds.append(options.campaignId)
    }

    func finish() {
        onFinish()
    }
}
