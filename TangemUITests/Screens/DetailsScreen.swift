//
//  DetailsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import Foundation
import TangemAccessibilityIdentifiers

final class DetailsScreen: ScreenBase<DetailsScreenElement> {
    private lazy var addNewWallet = anyElement(.addNewWallet)
    private lazy var contactSupportButton = button(.contactSupport)
    private lazy var appSettingsButton = button(.appSettings)
    private lazy var buyWalletButton = button(.buyWallet)
    private lazy var termsOfServiceButton = button(.termsOfService)
    private lazy var appVersionLabel = staticText(.appVersion)

    func openWalletSettings(for walletName: String) -> CardSettingsScreen {
        XCTContext.runActivity(named: "Open wallet settings for wallet: \(walletName)") { _ in
            let specificWalletButton = app.buttons[WalletSettingsAccessibilityIdentifiers.walletSettingsButton(name: walletName)]
            specificWalletButton.waitAndTap()
            return CardSettingsScreen(app)
        }
    }

    func openWalletSettings() -> CardSettingsScreen {
        XCTContext.runActivity(named: "Open settings for the current wallet") { _ in
            let walletButton = app.buttons
                .matching(NSPredicate(format: "identifier BEGINSWITH %@", "walletSettingsButton_"))
                .firstMatch
            waitAndAssertTrue(walletButton, "A saved wallet settings row should exist")
            walletButton.waitAndTap()
            return CardSettingsScreen(app)
        }
    }

    @discardableResult
    func openWalletConnections() -> WalletConnectionsScreen {
        XCTContext.runActivity(named: "Open WalletConnect") { _ in
            let walletConnectButton = button(.walletConnectButton)
            walletConnectButton.waitAndTap()
            return WalletConnectionsScreen(app)
        }
    }

    @discardableResult
    func tapAddNewWallet() -> Self {
        XCTContext.runActivity(named: "Add new wallet") { _ in
            addNewWallet.waitAndTap()
            return self
        }
    }

    @discardableResult
    func cancelScan() -> Self {
        XCTContext.runActivity(named: "Close scan alert") { _ in
            app.buttons["Cancel"].waitAndTapWithScroll()
            return self
        }
    }

    @discardableResult
    func contactSupport() -> MailFallbackScreen {
        XCTContext.runActivity(named: "Tap contact support button") { _ in
            contactSupportButton.waitAndTap()
            return MailFallbackScreen(app)
        }
    }

    @discardableResult
    func openAppSettings() -> AppSettingsScreen {
        XCTContext.runActivity(named: "Tap App Settings button") { _ in
            appSettingsButton.waitAndTap()
            return AppSettingsScreen(app)
        }
    }

    @discardableResult
    func goBackToMain() -> MainScreen {
        XCTContext.runActivity(named: "Go back to main screen") { _ in
            app.navigationBars.buttons["Back"].waitAndTap()
            return MainScreen(app)
        }
    }

    @discardableResult
    func openEnvironmentSetup() -> EnvironmentSetupScreen {
        XCTContext.runActivity(named: "Open Environment Setup") { _ in
            let environmentSetupButton = app.buttons["Environment setup"]
            waitAndAssertTrue(environmentSetupButton, "Environment setup button should exist")
            environmentSetupButton.waitAndTap()
            return EnvironmentSetupScreen(app)
        }
    }

    @discardableResult
    func verifySections(walletConnect: Bool) -> Self {
        XCTContext.runActivity(named: "Verify Details sections (walletConnect=\(walletConnect))") { _ in
            let walletConnectRow = button(.walletConnectButton)
            if walletConnect {
                waitAndAssertTrue(walletConnectRow, "WalletConnect row should be visible for this card type")
            } else {
                XCTAssertFalse(
                    walletConnectRow.waitForExistence(timeout: .conditional),
                    "WalletConnect row should NOT be visible for this card type"
                )
            }

            let walletPrefix = "walletSettingsButton_"
            let anySavedWallet = app.buttons.matching(
                NSPredicate(format: "identifier BEGINSWITH %@", walletPrefix)
            ).firstMatch
            waitAndAssertTrue(anySavedWallet, "At least one Saved wallet row should be visible")

            waitAndAssertTrue(addNewWallet, "Add new wallet button should be visible")
            waitAndAssertTrue(buyWalletButton, "Buy new wallet button should be visible")
            waitAndAssertTrue(appSettingsButton, "App Settings button should be visible")
            waitAndAssertTrue(contactSupportButton, "Contact Support button should be visible")
            waitAndAssertTrue(termsOfServiceButton, "Terms of Service button should be visible")

            scrollToElement(appVersionLabel, attempts: .lazy)
            waitAndAssertTrue(appVersionLabel, "App version footer should be visible")

            return self
        }
    }

    @discardableResult
    func openToSScreen() -> TermsOfServiceScreen {
        XCTContext.runActivity(named: "Open 'ToS' screen") { _ in
            waitAndAssertTrue(termsOfServiceButton, "'ToS' button should exist")
            termsOfServiceButton.waitAndTap()
            return TermsOfServiceScreen(app)
        }
    }
    
    @discardableResult
    func assertContactSupportButtonExists() -> Self {
        XCTContext.runActivity(named: "Verify 'Contact Support' button exists") { _ in
            waitAndAssertTrue(contactSupportButton, "'Contact Support' button should exist")
            return self
        }
    }
    
    private func anyElement(_ element: DetailsScreenElement) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: element.accessibilityIdentifier)
            .firstMatch
    }
}

enum DetailsScreenElement: UIElement {
    case walletConnectButton
    case addNewWallet
    case buyWallet
    case contactSupport
    case appSettings
    case termsOfService
    case appVersion

    var accessibilityIdentifier: String {
        switch self {
        case .walletConnectButton:
            return WalletConnectAccessibilityIdentifiers.detailsButton
        case .addNewWallet:
            return DetailsAccessibilityIdentifiers.addNewWallet
        case .buyWallet:
            return DetailsAccessibilityIdentifiers.buyWalletButton
        case .contactSupport:
            return DetailsAccessibilityIdentifiers.contactSupport
        case .appSettings:
            return DetailsAccessibilityIdentifiers.appSettings
        case .termsOfService:
            return DetailsAccessibilityIdentifiers.termsOfService
        case .appVersion:
            return DetailsAccessibilityIdentifiers.appVersion
        }
    }
}
