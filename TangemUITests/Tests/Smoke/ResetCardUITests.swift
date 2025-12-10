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

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .openWalletSettings(for: "Wallet")
            .openDeviceSettings()
            .validateScreenElements()
            .scanMockWallet(name: .wallet2)
            .openResetToFactorySettings()

        ResetCardScreen(app)
            .validateScreenElements(by: .wallet2)
            .validateResetButtonIsDisabled()
            .toggleAccessToCardCheckbox()
            .validateResetButtonIsDisabled()
            .toggleAccessCodeCheckbox()
            .validateResetButtonIsEnabled()
            .toggleAccessToCardCheckbox()
            .validateResetButtonIsDisabled()
    }

    func testResetWalletToFactorySettings_CheckboxBehavior() throws {
        setAllureId(3987)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet)
            .openDetails()
            .openWalletSettings(for: "Wallet")
            .openDeviceSettings()
            .validateScreenElements()
            .scanMockWallet(name: .wallet)
            .openResetToFactorySettings()

        ResetCardScreen(app)
            .validateScreenElements(by: .wallet)
            .validateResetButtonIsDisabled()
            .toggleAccessToCardCheckbox()
            .validateResetButtonIsDisabled()
            .toggleAccessCodeCheckbox()
            .validateResetButtonIsEnabled()
            .toggleAccessToCardCheckbox()
            .validateResetButtonIsDisabled()
    }

    func testResetWalletNoBackupToFactorySettings_CheckboxBehavior() throws {
        setAllureId(3988)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .walletNoBackup)
            .openDetails()
            .openWalletSettings(for: "Wallet")
            .openDeviceSettings()
            .validateScreenElements()
            .scanMockWallet(name: .walletNoBackup)
            .openResetToFactorySettings()

        ResetCardScreen(app)
            .validateScreenElements(by: .walletNoBackup)
            .validateResetButtonIsDisabled()
            .toggleAccessToCardCheckbox()
            .validateResetButtonIsEnabled()
    }
}
