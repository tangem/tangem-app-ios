//
//  BaseTestCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

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
        scenarios: [ScenarioConfig] = []
    ) {
        var arguments = ["--uitesting", "--alpha"]

        arguments.append(contentsOf: ["-tangem_api_type", tangemApiType?.rawValue ?? TangemAPI.prod.rawValue])

        arguments.append(contentsOf: ["-api_express", expressApiType?.rawValue ?? ExpressAPI.production.rawValue])

        arguments.append(contentsOf: ["-staking_api_type", stakingApiType?.rawValue ?? StakingAPI.prod.rawValue])

        if skipToS {
            arguments.append("-uitest-skip-tos")
        }

        app.launchArguments = arguments
        app.launchEnvironment = ["UITEST": "1"]

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
        let startCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let finishCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))

        startCoordinate.press(forDuration: 0.05, thenDragTo: finishCoordinate)
    }
}

extension XCUIApplication {
    func hideKeyboard() {
        toolbars.firstMatch.buttons["hideKeyboard"].waitAndTap()
    }
}
