//
//  AmplitudeExposureTrackingProvider.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Experiment

final class AmplitudeExposureTrackingProvider: ExposureTrackingProvider {
    func track(exposure: Exposure) {
        var props: [String: Any] = ["flag_key": exposure.flagKey]
        if let variant = exposure.variant {
            props["variant"] = variant
        }
        if let experimentKey = exposure.experimentKey {
            props["experiment_key"] = experimentKey
        }
        if let metadata = exposure.metadata {
            props["metadata"] = metadata
        }
        AmplitudeWrapper.shared.track(eventType: "$exposure", eventProperties: props)
    }
}
