//
//  WireMockClient.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import XCTest

final class WireMockClient {
    private let baseURL: String

    init(baseURL: String? = nil) {
        // Use WireMockPortResolver for per-simulator port isolation in parallel tests
        self.baseURL = baseURL ?? WireMockPortResolver.wireMockBaseURL
    }

    // MARK: - Scenario Management

    /// Get all scenarios
    func getAllScenarios() async throws -> [WireMockScenario] {
        let url = URL(string: "\(baseURL)/__admin/scenarios")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WireMockError.httpError(response)
        }

        let scenariosResponse = try JSONDecoder().decode(WireMockScenariosResponse.self, from: data)
        return scenariosResponse.scenarios
    }

    /// Reset all scenarios to "Started" state
    func resetAllScenarios() async throws {
        let url = URL(string: "\(baseURL)/__admin/scenarios/reset")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WireMockError.httpError(response)
        }
    }

    /// Reset specific scenario to "Started" state
    func resetScenario(_ scenarioName: String) async throws {
        let encodedName = scenarioName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? scenarioName
        let url = URL(string: "\(baseURL)/__admin/scenarios/\(encodedName)/state")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WireMockError.httpError(response)
        }
    }

    /// Set specific state for scenario
    func setScenarioState(_ scenarioName: String, state: String) async throws {
        let encodedName = scenarioName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? scenarioName
        let url = URL(string: "\(baseURL)/__admin/scenarios/\(encodedName)/state")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let stateRequest = WireMockScenarioStateRequest(state: state)
        request.httpBody = try JSONEncoder().encode(stateRequest)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WireMockError.httpError(response)
        }
    }

    /// Check current scenario state
    func getScenarioState(_ scenarioName: String) async throws -> String? {
        let scenarios = try await getAllScenarios()
        return scenarios.first { $0.name == scenarioName }?.state
    }

    // MARK: - Sync Wrappers for XCTest

    func resetAllScenariosSync() {
        let expectation = XCTestExpectation(description: "Reset all scenarios")
        Task {
            do {
                try await resetAllScenarios()
                expectation.fulfill()
            } catch {
                XCTFail("Failed to reset all scenarios: \(error)")
                expectation.fulfill()
            }
        }
        XCTestCase().wait(for: [expectation], timeout: .networkRequest)
    }

    func setScenarioStateSync(_ scenarioName: String, state: String) {
        let expectation = XCTestExpectation(description: "Set scenario state")
        Task {
            do {
                try await setScenarioState(scenarioName, state: state)
                expectation.fulfill()
            } catch {
                XCTFail("Failed to set scenario state for \(scenarioName): \(error)")
                expectation.fulfill()
            }
        }
        XCTestCase().wait(for: [expectation], timeout: .networkRequest)
    }

    func resetScenarioSync(_ scenarioName: String) {
        let expectation = XCTestExpectation(description: "Reset scenario")
        Task {
            do {
                try await resetScenario(scenarioName)
                expectation.fulfill()
            } catch {
                XCTFail("Failed to reset scenario \(scenarioName): \(error)")
                expectation.fulfill()
            }
        }
        XCTestCase().wait(for: [expectation], timeout: .networkRequest)
    }
}
