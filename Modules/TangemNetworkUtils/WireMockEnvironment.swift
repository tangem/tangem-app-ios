//
//  WireMockEnvironment.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Dynamic WireMock base URL for parallel test execution support.
/// Reads from environment variable, falls back to remote server for local development.
/// NOTE: Keep fallback in sync with WireMockPortResolver.wireMockBaseURL
public enum WireMockEnvironment {
    public static var baseURL: String {
        // Maestro passes launch arguments via UserDefaults, not ProcessInfo environment
        ProcessInfo.processInfo.environment["WIREMOCK_BASE_URL"]
            ?? UserDefaults.standard.string(forKey: "WIREMOCK_BASE_URL")
            ?? "http://localhost:8081"
    }
}
