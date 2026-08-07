//
//  CustomerIOConfigProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Reads the CDP API key from `ios_cio_config.json` in the target's own bundle.
/// Foundation-only on purpose: also compiled into the Notification Service Extension,
/// which must not link `TangemModules` — that would blow the NSE memory limit.
enum CustomerIOConfigProvider {
    private static let fileName = "ios_cio_config"

    static let cdpApiKey: String? = {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            return handleConfigError("\(fileName).json not found in the bundle. Check Copy Bundle Resources for this target.")
        }

        do {
            guard let key = try parseKey(from: Data(contentsOf: url)) else {
                return handleConfigError("\(fileName).json contains an empty API key.")
            }
            return key
        } catch {
            return handleConfigError("Failed to read \(fileName).json: \(error)")
        }
    }()

    private static func parseKey(from data: Data) throws -> String? {
        let key = try JSONDecoder().decode(Config.self, from: data).iosApiKey
        return key.isEmpty ? nil : key
    }

    /// Traps in Internal/Debug to catch bundling mistakes; `nil` in production, where Customer.io is optional.
    private static func handleConfigError(_ message: @autoclosure () -> String) -> String? {
        #if INTERNAL || DEBUG
        preconditionFailure(message())
        #else
        return nil
        #endif
    }

    private struct Config: Decodable {
        let iosApiKey: String
    }
}
