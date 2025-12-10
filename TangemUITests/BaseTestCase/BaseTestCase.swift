//
//  BaseTestCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers
import XCTest

/// Hot wallet types for mock repository.
/// Uses seed identifiers that are deterministically converted to BIP39 mnemonics.
/// TEST WALLETS ONLY - Never use for real funds.
enum HotWallet: String {
    case hotWallet1 = "tangem_uitest_wallet_1"
    case hotWallet2 = "tangem_uitest_wallet_2"

    /// The seed identifier used for deterministic mnemonic generation.
    /// This value is passed to the app and converted to a mnemonic via DeterministicMnemonicGenerator.
    var seed: String {
        rawValue
    }
}

class BaseTestCase: XCTestCase {
    let app = XCUIApplication()

    // MARK: - WireMock Support

    lazy var wireMockClient = WireMockClient()
    private var activeScenarios: [String: String] = [:]

    override func setUp() {
        super.setUp()

        continueAfterFailure = false
    }

    override func tearDown() {
        app.launchArguments.removeAll()
        app.launchEnvironment.removeAll()
        app.terminate()

        // Reset only active WireMock scenarios after each test
        if !activeScenarios.isEmpty {
            XCTContext.runActivity(named: "Reset active WireMock scenarios") { _ in
                for scenarioName in activeScenarios.keys {
                    wireMockClient.resetScenarioSync(scenarioName)
                }
            }
            activeScenarios.removeAll()
        }

        super.tearDown()
    }

    func launchApp(
        tangemApiType: TangemAPI? = nil,
        expressApiType: ExpressAPI? = nil,
        stakingApiType: StakingAPI? = nil,
        skipToS: Bool = true,
        clearStorage: Bool = false,
        disableMobileWallet: Bool = false,
        mockHotWallets: [HotWallet] = [],
        scenarios: [ScenarioConfig] = []
    ) {
        var arguments = ["--uitesting", "--alpha"]

        arguments.append(contentsOf: [
            "-tangem_api_type", tangemApiType?.rawValue ?? TangemAPI.prod.rawValue,
        ])

        arguments.append(contentsOf: [
            "-api_express", expressApiType?.rawValue ?? ExpressAPI.production.rawValue,
        ])

        arguments.append(contentsOf: [
            "-stake_kit_api_type", stakingApiType?.rawValue ?? StakingAPI.prod.rawValue,
        ])

        if skipToS {
            arguments.append("-uitest-skip-tos")
        }

        if clearStorage {
            arguments.append("-uitest-clear-storage")
        }

        if disableMobileWallet {
            arguments.append("-uitest-disable-mobile-wallet")
        }

        var launchEnvironment = ["UITEST": "1"]

        // Configure mock repository if hot wallets are provided
        if !mockHotWallets.isEmpty {
            arguments.append("-uitest-mock-repository")

            // Pass seed identifiers as JSON array in launch environment
            // Seeds are converted to mnemonics in the app via DeterministicMnemonicGenerator
            let seeds = mockHotWallets.map { $0.seed }
            if let seedsJSON = try? JSONEncoder().encode(seeds),
               let seedsString = String(data: seedsJSON, encoding: .utf8) {
                launchEnvironment["UITEST_MOCK_WALLET_SEEDS"] = seedsString
            }
        }

        app.launchArguments = arguments
        app.launchEnvironment = launchEnvironment

        // Setup WireMock scenarios before launching the app
        setupWireMockScenarios(scenarios)

        app.launch()
    }

    // MARK: - WireMock Scenario Management

    func setupWireMockScenarios(_ scenarios: [ScenarioConfig]) {
        guard !scenarios.isEmpty else { return }

        XCTContext.runActivity(named: "Setup WireMock scenarios") { _ in
            // Set initial states for specified scenarios
            for scenario in scenarios {
                wireMockClient.setScenarioStateSync(scenario.name, state: scenario.initialState)

                if scenario.initialState != "Started" {
                    activeScenarios[scenario.name] = scenario.initialState
                }
            }
        }
    }

    func pullToRefresh() {
        XCTContext.runActivity(named: "Perform pull to refresh") { _ in
            // Try to find common scrollable elements in order of preference
            let startCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            let finishCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1))

            startCoordinate.press(forDuration: 0.1, thenDragTo: finishCoordinate)

            // Wait for refresh to complete by waiting for state to change back to idle
            let refreshStateIdle = app.otherElements[MainAccessibilityIdentifiers.refreshStateIdle]
            XCTAssertTrue(
                refreshStateIdle.waitForExistence(timeout: .conditional),
                "Refresh state should change to idle when refresh is complete"
            )
        }
    }

    // MARK: - App Lifecycle Management

    func minimizeApp() {
        XCTContext.runActivity(named: "Minimize application") { _ in
            XCUIDevice.shared.press(.home)
        }
    }

    func maximizeApp() {
        XCTContext.runActivity(named: "Maximize application") { _ in
            app.activate()
            XCTAssertTrue(
                app.wait(for: .runningForeground, timeout: 5.0),
                "App should be running in foreground"
            )
        }
    }

    // MARK: - Alert Handling

    func waitAndDismissErrorAlert(
        actionName: String,
        expectedMessage: String = "currently unavailable",
        buttonTitle: String = "OK"
    ) {
        XCTContext.runActivity(named: "Verify and dismiss error alert for \(actionName)") { _ in
            let alert = app.alerts.firstMatch
            XCTAssertTrue(
                alert.waitForExistence(timeout: .robustUIUpdate),
                "Error alert should be displayed after tapping \(actionName) button"
            )

            let alertMessage = alert.staticTexts.element(
                matching: NSPredicate(format: "label CONTAINS %@", expectedMessage)
            ).firstMatch
            XCTAssertTrue(
                alertMessage.exists,
                "Alert should contain message about action being unavailable"
            )

            alert.buttons[buttonTitle].waitAndTap()
        }
    }
}

extension XCUIApplication {
    func hideKeyboard() {
        toolbars.firstMatch.buttons["hideKeyboard"].waitAndTap()
    }
}
