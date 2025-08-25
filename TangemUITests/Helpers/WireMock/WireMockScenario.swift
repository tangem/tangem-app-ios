//
//  WireMockScenario.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - WireMock Scenario Models

struct WireMockScenario: Codable {
    let id: String
    let name: String
    let state: String
    let possibleStates: [String]
}

struct WireMockScenariosResponse: Codable {
    let scenarios: [WireMockScenario]
}

struct WireMockScenarioStateRequest: Codable {
    let state: String
}

// MARK: - Scenario Configuration

struct ScenarioConfig {
    let name: String
    let initialState: String

    init(name: String, initialState: String = "Started") {
        self.name = name
        self.initialState = initialState
    }
}
