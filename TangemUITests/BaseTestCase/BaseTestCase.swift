//
//  BaseTestCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

class BaseTestCase: XCTestCase {
    let app = XCUIApplication()

    // MARK: - WireMock Support

    lazy var wireMockClient = WireMockClient()
    private var modifiedScenarios: [String] = []

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    override func tearDown() {
        resetModifiedWireMockScenarios()

        app.launchArguments.removeAll()
        app.launchEnvironment.removeAll()
        app.terminate()

        super.tearDown()
    }

    func launchApp(
        tangemApiType: TangemAPI? = nil,
        expressApiType: ExpressAPI? = nil,
        stakingApiType: StakingAPI? = nil,
        skipToS: Bool = true,
        clearStorage: Bool = false,
        scenarios: [ScenarioConfig] = []
    ) {
        var arguments: [String] = []

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

        app.launchArguments = arguments

        // Build launch environment with resolved WireMock URL for parallel test support
        // WireMockPortResolver determines the correct port based on simulator UDID
        let wireMockURL = WireMockPortResolver.wireMockBaseURL

        var launchEnvironment = ["UITEST": "1"]
        launchEnvironment["WIREMOCK_BASE_URL"] = wireMockURL
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
                if !modifiedScenarios.contains(scenario.name) {
                    modifiedScenarios.append(scenario.name)
                }
            }
        }
    }

    private func resetModifiedWireMockScenarios() {
        guard !modifiedScenarios.isEmpty else { return }

        XCTContext.runActivity(named: "Reset modified WireMock scenarios") { _ in
            for scenarioName in modifiedScenarios {
                wireMockClient.resetScenarioSync(scenarioName)
            }
            modifiedScenarios.removeAll()
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
            XCTAssertTrue(refreshStateIdle.waitForExistence(timeout: .conditional), "Refresh state should change to idle when refresh is complete")
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
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5.0), "App should be running in foreground")
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
