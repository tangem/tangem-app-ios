//
//  StakingDetailsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class StakingDetailsScreen: ScreenBase<StakingDetailsScreenElement> {
    private lazy var title = scrollView(.title)
    private lazy var annualPercentageRateValue = staticText(.annualPercentageRateValue)
    private lazy var availableValue = staticText(.availableValue)
    private lazy var unbondingPeriodValue = staticText(.unbondingPeriodValue)
    private lazy var rewardClaimingValue = staticText(.rewardClaimingValue)
    private lazy var rewardScheduleValue = staticText(.rewardScheduleValue)
    private lazy var yourStakesHeader = staticText(.yourStakesHeader)
    private lazy var activeStakeRow = button(.activeStakeRow)
    private lazy var withdrawStakeRow = button(.withdrawStakeRow)
    // Non-tappable row: SwiftUI may expose the identifier on a container other than `otherElement`.
    private lazy var unstakingStakeRow = app.descendants(matching: .any)[StakingAccessibilityIdentifiers.unstakingStakeRow].firstMatch
    private lazy var rewardClaimBlock = button(.rewardClaimBlock)
    private lazy var noRewardsToClaim = staticText(.noRewardsToClaim)

    @discardableResult
    func validate() -> Self {
        XCTContext.runActivity(named: "Validate Staking Details Screen") { _ in
            XCTAssertTrue(title.waitForExistence(timeout: .robustUIUpdate), "Title should exist")
            XCTAssertTrue(app.staticTexts["Annual percentage rate"].waitForExistence(timeout: .robustUIUpdate))
            XCTAssertTrue(app.staticTexts["Available"].waitForExistence(timeout: .robustUIUpdate))
            XCTAssertTrue(app.staticTexts["Unbonding Period"].waitForExistence(timeout: .robustUIUpdate))
            XCTAssertTrue(app.staticTexts["Reward claiming"].waitForExistence(timeout: .robustUIUpdate))
            XCTAssertTrue(app.staticTexts["Reward schedule"].waitForExistence(timeout: .robustUIUpdate))
            return self
        }
    }

    func validateValues() -> Self {
        XCTContext.runActivity(named: "Validate Staking Details Values") { _ in
            XCTAssertFalse(getAnnualPercentageRateValue().isEmpty, "Annual percentage rate value should not be empty")
            XCTAssertFalse(getAvailableValue().isEmpty, "Available value should not be empty")
            XCTAssertFalse(getUnbondingPeriodValue().isEmpty, "Unbonding period value should not be empty")
            XCTAssertFalse(getRewardClaimingValue().isEmpty, "Reward claiming value should not be empty")
            XCTAssertFalse(getRewardScheduleValue().isEmpty, "Reward schedule value should not be empty")
            return self
        }
    }

    // MARK: - Element Value Getters

    func getAnnualPercentageRateValue() -> String {
        return annualPercentageRateValue.waitForExistence(timeout: .robustUIUpdate) ? annualPercentageRateValue.label : ""
    }

    func getAvailableValue() -> String {
        return availableValue.waitForExistence(timeout: .robustUIUpdate) ? availableValue.label : ""
    }

    func getUnbondingPeriodValue() -> String {
        return unbondingPeriodValue.waitForExistence(timeout: .robustUIUpdate) ? unbondingPeriodValue.label : ""
    }

    func getRewardClaimingValue() -> String {
        return rewardClaimingValue.waitForExistence(timeout: .robustUIUpdate) ? rewardClaimingValue.label : ""
    }

    func getRewardScheduleValue() -> String {
        return rewardScheduleValue.waitForExistence(timeout: .robustUIUpdate) ? rewardScheduleValue.label : ""
    }

    // MARK: - Action Methods

    @discardableResult
    func proceedToSendScreen() -> StakingSendScreen {
        XCTContext.runActivity(named: "Tap Stake button") { _ in
            let stakeButton = app.buttons[StakingAccessibilityIdentifiers.stakeButton]
            XCTAssertTrue(stakeButton.waitForExistence(timeout: .robustUIUpdate), "Stake button should exist")
            XCTAssertTrue(stakeButton.isEnabled, "Stake button should be enabled")

            stakeButton.tap()
        }
        return StakingSendScreen(app)
    }

    // MARK: - Your Stakes

    @discardableResult
    func assertYourStakesTitle() -> Self {
        XCTContext.runActivity(named: "Assert 'Your stakes' section is displayed") { _ in
            waitAndAssertTrue(yourStakesHeader, "'Your stakes' section header should be displayed")
            return self
        }
    }

    @discardableResult
    func assertActiveStakeDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert active staking row is displayed") { _ in
            waitAndAssertTrue(activeStakeRow, "Active staking row should be displayed")
            return self
        }
    }

    @discardableResult
    func assertWithdrawEntryDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert withdraw entry is displayed") { _ in
            waitAndAssertTrue(withdrawStakeRow, "Withdraw ('Unstaked') entry should be displayed")
            return self
        }
    }

    @discardableResult
    func assertWithdrawEntryNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert withdraw entry is no longer displayed") { _ in
            XCTAssertTrue(
                withdrawStakeRow.waitForNonExistence(timeout: .robustUIUpdate),
                "Withdraw ('Unstaked') entry should disappear after withdrawing"
            )
            return self
        }
    }

    @discardableResult
    func assertUnstakingEntryDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert unstaking entry is displayed") { _ in
            waitAndAssertTrue(unstakingStakeRow, "Unstaking entry should be displayed")
            return self
        }
    }

    @discardableResult
    func assertNoRewardsToClaim() -> Self {
        XCTContext.runActivity(named: "Assert 'no rewards to claim' text is displayed") { _ in
            waitAndAssertTrue(noRewardsToClaim, "'No rewards to claim' text should be displayed")
            return self
        }
    }

    /// Tapping the active stake opens the unstake flow, which starts on the amount step (partial unstake).
    func tapActiveStake() -> StakingSendScreen {
        XCTContext.runActivity(named: "Tap active staking row") { _ in
            activeStakeRow.waitAndTap()
            return StakingSendScreen(app)
        }
    }

    func tapWithdrawEntry() -> SendSummaryScreen {
        XCTContext.runActivity(named: "Tap withdraw entry") { _ in
            withdrawStakeRow.waitAndTap()
            return SendSummaryScreen(app)
        }
    }

    func tapRewardsBlock() -> SendSummaryScreen {
        XCTContext.runActivity(named: "Tap rewards claim block") { _ in
            rewardClaimBlock.waitAndTap()
            return SendSummaryScreen(app)
        }
    }
}

enum StakingDetailsScreenElement: String, UIElement {
    case title
    case annualPercentageRateValue
    case availableValue
    case unbondingPeriodValue
    case rewardClaimingValue
    case rewardScheduleValue
    case yourStakesHeader
    case activeStakeRow
    case unstakingStakeRow
    case withdrawStakeRow
    case rewardClaimBlock
    case noRewardsToClaim

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return StakingAccessibilityIdentifiers.title
        case .annualPercentageRateValue:
            return StakingAccessibilityIdentifiers.annualPercentageRateValue
        case .availableValue:
            return StakingAccessibilityIdentifiers.availableValue
        case .unbondingPeriodValue:
            return StakingAccessibilityIdentifiers.unbondingPeriodValue
        case .rewardClaimingValue:
            return StakingAccessibilityIdentifiers.rewardClaimingValue
        case .rewardScheduleValue:
            return StakingAccessibilityIdentifiers.rewardScheduleValue
        case .yourStakesHeader:
            return StakingAccessibilityIdentifiers.yourStakesHeader
        case .activeStakeRow:
            return StakingAccessibilityIdentifiers.activeStakeRow
        case .unstakingStakeRow:
            return StakingAccessibilityIdentifiers.unstakingStakeRow
        case .withdrawStakeRow:
            return StakingAccessibilityIdentifiers.withdrawStakeRow
        case .rewardClaimBlock:
            return StakingAccessibilityIdentifiers.rewardClaimBlock
        case .noRewardsToClaim:
            return StakingAccessibilityIdentifiers.noRewardsToClaim
        }
    }
}
