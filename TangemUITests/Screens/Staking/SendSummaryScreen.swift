//
//  SendSummaryScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendSummaryScreen: ScreenBase<SendSummaryScreenElement> {
    private lazy var title = staticText(.title)
    private lazy var stakeButton = button(.stakeButton)
    private lazy var amountValue = staticText(.amountValue)
    private lazy var validatorBlock = staticText(.validatorBlock)
    private lazy var networkFeeBlock = staticText(.networkFeeBlock)

    @discardableResult
    func validateAmountValue(_ expectedAmount: String) -> Self {
        XCTContext.runActivity(named: "Validate amount value: \(expectedAmount)") { _ in
            XCTAssertTrue(amountValue.waitForExistence(timeout: .robustUIUpdate), "Amount value element should exist")
            XCTAssertTrue(amountValue.label.contains(expectedAmount), "Amount value should contain '\(expectedAmount)'")
            return self
        }
    }

    @discardableResult
    func validate() -> Self {
        XCTContext.runActivity(named: "Validate Send Summary Screen") { _ in
            XCTAssertTrue(validatorBlock.waitForExistence(timeout: .robustUIUpdate), "Validator block should be displayed")
            XCTAssertTrue(networkFeeBlock.waitForExistence(timeout: .robustUIUpdate), "Network fee block should be displayed")
            XCTAssertTrue(stakeButton.waitForExistence(timeout: .robustUIUpdate), "Stake button should exist")
            XCTAssertTrue(stakeButton.isEnabled, "Stake button should be enabled")
            XCTAssertTrue(stakeButton.label.contains("Stake"), "Stake button should have 'Stake' text")
            return self
        }
    }
}

enum SendSummaryScreenElement: String, UIElement {
    case title
    case stakeButton
    case amountValue
    case validatorBlock
    case networkFeeBlock

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return CommonUIAccessibilityIdentifiers.title
        case .stakeButton:
            return StakingAccessibilityIdentifiers.stakeButton
        case .amountValue:
            return CommonUIAccessibilityIdentifiers.sendAmountViewValue
        case .validatorBlock:
            return StakingAccessibilityIdentifiers.validatorBlock
        case .networkFeeBlock:
            return StakingAccessibilityIdentifiers.networkFeeBlock
        }
    }
}
