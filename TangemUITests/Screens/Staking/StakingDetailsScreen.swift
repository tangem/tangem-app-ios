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
}

enum StakingDetailsScreenElement: String, UIElement {
    case title
    case annualPercentageRateValue
    case availableValue
    case unbondingPeriodValue
    case rewardClaimingValue
    case rewardScheduleValue

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
        }
    }
}
