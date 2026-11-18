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

        let pinnedVariants = makeVariantOverrides(from: ProcessInfo.processInfo.arguments)
        let originalService = InjectedValues[\.experimentService]

        InjectedValues[\.experimentService] = UITestExperimentService(
            wrapped: originalService,
            variantOverrides: Constants.defaultVariantOverrides.merging(pinnedVariants) { _, pinned in pinned },
            hasPinnedVariants: pinnedVariants.isNotEmpty
        )
    }
}

// MARK: - Private

private extension UITestExperimentServiceConfigurator {
    func makeVariantOverrides(from arguments: [String]) -> [ExperimentFeatureFlagKey: String] {
        arguments.reduce(into: [:]) { overrides, argument in
            guard argument.hasPrefix(Constants.overridePrefix) else {
                return
            }

            let parts = argument
                .dropFirst(Constants.overridePrefix.count)
                .split(separator: "-", maxSplits: 1)

            guard parts.count == 2, let key = ExperimentFeatureFlagKey(rawValue: String(parts[0])) else {
                return
            }

            overrides[key] = String(parts[1])
        }
    }
}

// MARK: - Constants

private extension UITestExperimentServiceConfigurator {
    enum Constants {
        static let overridePrefix = "-uitest-experiment-"
        static let defaultVariantOverrides: [ExperimentFeatureFlagKey: String] = [.yieldModePromo: "off"]
    }
}
