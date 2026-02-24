//
//  WireMockPortResolver.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Resolves WireMock port based on simulator UDID for parallel test execution.
enum WireMockPortResolver {
    private static let basePort = 8081

    /// Resolution priority:
    /// 1. `SIMULATOR_PORT_MAPPING` + `SIMULATOR_UDID` for per-device isolation
    /// 2. Default for local run: `localhost:8081`
    static var wireMockBaseURL: String {
        let portOffset = resolvePortOffsetFromMapping() ?? 0
        let port = basePort + portOffset
        return "http://localhost:\(port)"
    }

    /// Resolves port offset from `SIMULATOR_PORT_MAPPING` env variable.
    /// Format: `"UDID1:0,UDID2:1,UDID3:2"`
    private static func resolvePortOffsetFromMapping() -> Int? {
        guard let mapping = ProcessInfo.processInfo.environment["SIMULATOR_PORT_MAPPING"],
              !mapping.isEmpty else {
            return nil
        }

        let currentUDID = simulatorUDID
        guard !currentUDID.isEmpty else {
            return nil
        }

        for pair in mapping.split(separator: ",") {
            let parts = pair.split(separator: ":")
            if parts.count == 2,
               String(parts[0]) == currentUDID,
               let offset = Int(parts[1]) {
                return offset
            }
        }

        return nil
    }

    private static var simulatorUDID: String {
        if let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"], !udid.isEmpty {
            return udid
        }

        if let udid = ProcessInfo.processInfo.environment["DEVICE_UDID"], !udid.isEmpty {
            return udid
        }

        // Fallback: extract UDID from simulator HOME path
        if let home = ProcessInfo.processInfo.environment["HOME"],
           let range = home.range(of: "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}", options: .regularExpression) {
            return String(home[range])
        }

        return ""
    }
}
