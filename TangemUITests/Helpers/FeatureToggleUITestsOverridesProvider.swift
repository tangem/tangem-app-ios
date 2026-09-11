//
//  FeatureToggleUITestsOverridesProvider.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Provides the run-wide feature toggle overrides passed from CI/Allure.
///
/// CI writes the `UITEST_FEATURE_TOGGLES` env variable into the Marathon `xctestrunEnv.test` block;
/// `BaseTestCase.launchApp` reads it here and forwards each pair to the app as a
/// `-uitest-feature-<name>-on` / `-off` launch argument (parsed in `ServicesManager`).
enum FeatureToggleUITestsOverridesProvider {
    /// Overrides declared for the whole run via the `UITEST_FEATURE_TOGGLES` env variable.
    /// Format: `"name=true,otherName=false"`, where a key is a `Feature.name`
    /// (e.g. `TWI-1259_tron_gasless`). Pairs with any other value are ignored.
    static var runOverrides: [String: Bool] {
        parse(ProcessInfo.processInfo.environment["UITEST_FEATURE_TOGGLES"])
    }

    private static func parse(_ raw: String?) -> [String: Bool] {
        guard let raw, !raw.isEmpty else { return [:] }

        var result: [String: Bool] = [:]
        for pair in raw.split(separator: ",") {
            let parts = pair.split(separator: "=")
            guard parts.count == 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces).lowercased()

            switch value {
            case "true": result[key] = true
            case "false": result[key] = false
            default: continue
            }
        }
        return result
    }
}
