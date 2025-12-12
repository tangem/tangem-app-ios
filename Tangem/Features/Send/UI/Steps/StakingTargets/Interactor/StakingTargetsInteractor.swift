//
//  StakingTargetsInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

protocol StakingTargetsInteractor {
    var targetsPublisher: AnyPublisher<[StakingTargetInfo], Never> { get }
    var selectedTargetPublisher: AnyPublisher<StakingTargetInfo, Never> { get }

    func userDidSelect(targetAddress: String)
}

class CommonStakingTargetsInteractor {
    private weak var input: StakingTargetsInput?
    private weak var output: StakingTargetsOutput?

    private let manager: StakingManager
    private let currentTarget: StakingTargetInfo?
    private let actionType: SendFlowActionType

    private let _targets = CurrentValueSubject<[StakingTargetInfo], Never>([])

    init(
        input: StakingTargetsInput,
        output: StakingTargetsOutput,
        manager: StakingManager,
        currentTarget: StakingTargetInfo? = nil,
        actionType: SendFlowActionType
    ) {
        self.input = input
        self.output = output
        self.manager = manager
        self.currentTarget = currentTarget
        self.actionType = actionType

        setupTargets()
    }
}

// MARK: - Private

private extension CommonStakingTargetsInteractor {
    func setupTargets() {
        guard let yield = manager.state.yieldInfo else {
            AppLogger.error(error: "StakingManager.Yields not found")
            return
        }

        let targets = yield.preferredTargets
            .filter { actionType == .restake ? $0 != currentTarget : true }

        guard !targets.isEmpty else {
            AppLogger.error(error: "Yield.Targets is empty")
            return
        }

        if let first = targets.first {
            output?.userDidSelect(target: first)
        }

        _targets.send(targets)
    }
}

// MARK: - StakingTargetsInteractor

extension CommonStakingTargetsInteractor: StakingTargetsInteractor {
    var targetsPublisher: AnyPublisher<[TangemStaking.StakingTargetInfo], Never> {
        _targets.eraseToAnyPublisher()
    }

    var selectedTargetPublisher: AnyPublisher<StakingTargetInfo, Never> {
        guard let input else {
            assertionFailure("StakingTargetsInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.selectedTargetPublisher
    }

    func userDidSelect(targetAddress: String) {
        guard let target = _targets.value.first(where: { $0.address == targetAddress }) else {
            return
        }

        output?.userDidSelect(target: target)
    }
}
