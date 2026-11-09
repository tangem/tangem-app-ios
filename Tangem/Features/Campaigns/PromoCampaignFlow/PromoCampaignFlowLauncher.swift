//
//  PromoCampaignFlowLauncher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol PromoCampaignFlowLaunching: AnyObject {
    var isFlowActive: Bool { get }

    func startFlow(campaignId: Int, userWalletId: UserWalletId)
}

protocol PromoCampaignFlow: AnyObject {
    var isStale: Bool { get }

    func start(with options: PromoCampaignCoordinator.Options)
}

final class PromoCampaignFlowLauncher {
    typealias FlowFactory = (_ onFinish: @escaping () -> Void) -> PromoCampaignFlow

    private let makeFlow: FlowFactory
    private var flow: PromoCampaignFlow?
    private var flowToken: UUID?

    init(makeFlow: @escaping FlowFactory = PromoCampaignFlowLauncher.makeCoordinator) {
        self.makeFlow = makeFlow
    }
}

// MARK: - PromoCampaignFlowLaunching

extension PromoCampaignFlowLauncher: PromoCampaignFlowLaunching {
    var isFlowActive: Bool {
        flow.map { !$0.isStale } ?? false
    }

    func startFlow(campaignId: Int, userWalletId: UserWalletId) {
        guard !isFlowActive else {
            return
        }

        let token = UUID()
        let flow = makeFlow { [weak self] in
            guard let self, flowToken == token else {
                return
            }

            self.flow = nil
            flowToken = nil
        }

        self.flow = flow
        flowToken = token
        flow.start(with: .init(campaignId: campaignId, userWalletId: userWalletId))
    }
}

// MARK: - Coordinator factory

extension PromoCampaignFlowLauncher {
    static func makeCoordinator(onFinish: @escaping () -> Void) -> PromoCampaignFlow {
        PromoCampaignCoordinator(
            dismissAction: { _ in onFinish() },
            popToRootAction: { _ in }
        )
    }
}

// MARK: - PromoCampaignFlow

extension PromoCampaignCoordinator: PromoCampaignFlow {}

// MARK: - DI

private struct PromoCampaignFlowLauncherKey: InjectionKey {
    static var currentValue: PromoCampaignFlowLaunching = PromoCampaignFlowLauncher()
}

extension InjectedValues {
    var promoCampaignFlowLauncher: PromoCampaignFlowLaunching {
        get { Self[PromoCampaignFlowLauncherKey.self] }
        set { Self[PromoCampaignFlowLauncherKey.self] = newValue }
    }
}
