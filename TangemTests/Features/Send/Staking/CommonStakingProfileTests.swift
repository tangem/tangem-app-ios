//
//  CommonStakingProfileTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import Testing
@testable import Tangem

@Suite("CommonStakingProfile")
struct CommonStakingProfileTests {
    // MARK: - stepPlan

    @Test("Editable stake: amount editable, validator selectable, summary fully editable")
    func stakeEditable() {
        let plan = CommonStakingProfile.stepPlan(for: stake(), isStakeAmountEditable: true, isPartialUnstakeAllowed: false)

        #expect(plan.amount == .editable(preset: nil))
        #expect(plan.hasValidatorSelection)
        #expect(plan.includesStakesCount == false)
        #expect(plan.summarySettings.amountEditableType == .editable)
        #expect(plan.summarySettings.destinationEditableType == .editable)
    }

    @Test("Non-editable stake: amount fixed to the action amount, validator still selectable")
    func stakeFixed() {
        let plan = CommonStakingProfile.stepPlan(for: stake(amount: 100), isStakeAmountEditable: false, isPartialUnstakeAllowed: false)

        #expect(plan.amount == .fixed(100))
        #expect(plan.hasValidatorSelection)
        #expect(plan.summarySettings.amountEditableType == .noEditable)
        #expect(plan.summarySettings.destinationEditableType == .editable)
    }

    @Test("Restake: fixed amount, selectable validator")
    func restake() {
        let action = StakingAction(amount: 5, targetType: .empty, type: .pending(.restake(passthrough: "p")))
        let plan = CommonStakingProfile.stepPlan(for: action, isStakeAmountEditable: true, isPartialUnstakeAllowed: false)

        #expect(plan.amount == .fixed(5))
        #expect(plan.hasValidatorSelection)
        #expect(plan.includesStakesCount == false)
        #expect(plan.summarySettings.amountEditableType == .noEditable)
        #expect(plan.summarySettings.destinationEditableType == .editable)
    }

    @Test("Partial unstake: amount preset-editable, no validator, summary editable, includes stakes count")
    func unstakePartialAllowed() {
        let plan = CommonStakingProfile.stepPlan(for: unstake(amount: 7), isStakeAmountEditable: true, isPartialUnstakeAllowed: true)

        #expect(plan.amount == .editable(preset: 7))
        #expect(plan.hasValidatorSelection == false)
        #expect(plan.includesStakesCount)
        #expect(plan.summarySettings.amountEditableType == .editable)
        #expect(plan.summarySettings.destinationEditableType == .editable)
    }

    @Test("Full unstake: amount fixed, summary not editable")
    func unstakePartialDisallowed() {
        let plan = CommonStakingProfile.stepPlan(for: unstake(amount: 7), isStakeAmountEditable: true, isPartialUnstakeAllowed: false)

        #expect(plan.amount == .fixed(7))
        #expect(plan.summarySettings.amountEditableType == .noEditable)
        #expect(plan.summarySettings.destinationEditableType == .noEditable)
    }

    @Test("Single action (withdraw): fixed amount, no validator, includes stakes count, nothing editable")
    func singleAction() {
        let action = StakingAction(amount: 3, targetType: .empty, type: .pending(.withdraw(passthroughs: ["p"])))
        let plan = CommonStakingProfile.stepPlan(for: action, isStakeAmountEditable: true, isPartialUnstakeAllowed: true)

        #expect(plan.amount == .fixed(3))
        #expect(plan.hasValidatorSelection == false)
        #expect(plan.includesStakesCount)
        #expect(plan.summarySettings.amountEditableType == .noEditable)
        #expect(plan.summarySettings.destinationEditableType == .noEditable)
    }

    // MARK: - makeAction

    @Test("Editable amount + selectable validator with no selection builds an empty-target stake action")
    func makeActionEditable() {
        let plan = CommonStakingProfile.stepPlan(for: stake(), isStakeAmountEditable: true, isPartialUnstakeAllowed: false)
        let action = CommonStakingProfile.makeAction(stepPlan: plan, action: stake(), amount: 5, target: nil)

        #expect(action.amount == 5)
        #expect(action.targetType == .empty)
        #expect(action.type == .stake)
    }

    @Test("Fixed amount ignores the passed value")
    func makeActionFixed() {
        let original = StakingAction(amount: 3, targetType: .empty, type: .pending(.withdraw(passthroughs: ["p"])))
        let plan = CommonStakingProfile.stepPlan(for: original, isStakeAmountEditable: true, isPartialUnstakeAllowed: true)
        let action = CommonStakingProfile.makeAction(stepPlan: plan, action: original, amount: 999, target: nil)

        #expect(action.amount == 3)
        #expect(action.type == original.type)
    }

    @Test("Preset-editable amount uses the edited value, falling back to the preset")
    func makeActionPresetEditable() {
        let original = unstake(amount: 7)
        let plan = CommonStakingProfile.stepPlan(for: original, isStakeAmountEditable: true, isPartialUnstakeAllowed: true)

        #expect(CommonStakingProfile.makeAction(stepPlan: plan, action: original, amount: 4, target: nil).amount == 4)
        #expect(CommonStakingProfile.makeAction(stepPlan: plan, action: original, amount: nil, target: nil).amount == 7)
    }

    // MARK: - Helpers

    private func stake(amount: Decimal = 0) -> StakingAction {
        StakingAction(amount: amount, targetType: .empty, type: .stake)
    }

    private func unstake(amount: Decimal) -> StakingAction {
        StakingAction(amount: amount, targetType: .empty, type: .unstake)
    }
}
