//
//  ResetCardUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import XCTest

final class ResetCardUITests: BaseTestCase {
    func testResetToFactorySettings_CheckboxBehavior() throws {
        setAllureId(3974)
        launchApp()

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .openWalletSettings(for: "Wallet")
            .openDeviceSettings()
            .validateScreenElements()
            .scanMockWallet(name: .wallet2)
            .openResetToFactorySettings()

        ResetCardScreen(app)
            .validateScreenElements()
            .validateResetButtonIsDisabled()
            .toggleAccessToCardCheckbox()
            .validateResetButtonIsDisabled()
            .toggleAccessCodeCheckbox()
            .validateResetButtonIsEnabled()
            .toggleAccessToCardCheckbox()
            .validateResetButtonIsDisabled()
    }
}
