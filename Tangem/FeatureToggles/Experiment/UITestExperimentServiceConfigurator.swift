//
//  UITestExperimentServiceConfigurator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct UITestExperimentServiceConfigurator: Initializable {
    func initialize() {
        guard AppEnvironment.current.isUITest else {
            return
        }

        let variantOverrides = makeVariantOverrides(from: ProcessInfo.processInfo.arguments)

        guard variantOverrides.isNotEmpty else {
            return
        }

        let originalService = InjectedValues[\.experimentService]

        InjectedValues[\.experimentService] = UITestExperimentService(
            wrapped: originalService,
            variantOverrides: variantOverrides
        )
    }
}

// MARK: - Private

private extension UITestExperimentServiceConfigurator {
    func makeVariantOverrides(from arguments: [String]) -> [ExperimentFeatureFlagKey: ExperimentFeatureVariantKey] {
        arguments.reduce(into: [:]) { overrides, argument in
            guard argument.hasPrefix(Constants.overridePrefix) else {
                return
            }

            let parts = argument
                .dropFirst(Constants.overridePrefix.count)
                .split(separator: "-", maxSplits: 1)

            guard parts.count == 2,
                  let key = ExperimentFeatureFlagKey(rawValue: String(parts[0])),
                  let variant = ExperimentFeatureVariantKey(rawValue: String(parts[1])) else {
                return
            }

            overrides[key] = variant
        }
    }
}

// MARK: - Constants

private extension UITestExperimentServiceConfigurator {
    enum Constants {
        static let overridePrefix = "-uitest-experiment-"
    }
}
