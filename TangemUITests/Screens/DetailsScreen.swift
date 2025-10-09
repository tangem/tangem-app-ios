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
    private lazy var scanCardOrRingButton = button(.scanCardOrRing)
    private lazy var contactSupportButton = button(.contactSupport)
    private lazy var appSettingsButtons = button(.appSettings)

    func openWalletSettings(for walletName: String) -> CardSettingsScreen {
        XCTContext.runActivity(named: "Open wallet settings for wallet: \(walletName)") { _ in
            let specificWalletButton = app.buttons[WalletSettingsAccessibilityIdentifiers.walletSettingsButton(name: walletName)]
            specificWalletButton.waitAndTap()
            return CardSettingsScreen(app)
        }
    }

    func openWalletConnections() -> WalletConnectionsScreen {
        XCTContext.runActivity(named: "Open WalletConnect") { _ in
            let walletConnectButton = button(.walletConnectButton)
            walletConnectButton.waitAndTap()
            return WalletConnectionsScreen(app)
        }
    }

    func scanCardOrRing() -> Self {
        XCTContext.runActivity(named: "Add new wallet") { _ in
            scanCardOrRingButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func cancelScan() -> Self {
        XCTContext.runActivity(named: "Close scan alert") { _ in
            app.buttons["Cancel"].waitAndTap()
            return self
        }
    }

    @discardableResult
    func contactSupport() -> MailScreen {
        XCTContext.runActivity(named: "Tap contact support button") { _ in
            contactSupportButton.waitAndTap()
            return MailScreen(app)
        }
    }

    @discardableResult
    func openAppSettings() -> AppSettingsScreen {
        XCTContext.runActivity(named: "Tap App Settings button") { _ in
            appSettingsButtons.waitAndTap()
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
}

enum DetailsScreenElement: UIElement {
    case walletConnectButton
    case scanCardOrRing
    case contactSupport
    case appSettings

    var accessibilityIdentifier: String {
        switch self {
        case .walletConnectButton:
            return WalletConnectAccessibilityIdentifiers.detailsButton
        case .scanCardOrRing:
            return "Scan card or ring"
        case .contactSupport:
            return "Contact support"
        case .appSettings:
            return "App settings"
        }
    }
}
