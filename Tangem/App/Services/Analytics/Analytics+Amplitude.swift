//
//  Analytics+Amplitude.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import AmplitudeSwift

protocol TangemAmplitude {
    func track(eventType: String, eventProperties: [String: Any])
}

extension Amplitude: TangemAmplitude {
    func track(eventType: String, eventProperties: [String: Any]) {
        track(eventType: eventType, eventProperties: eventProperties, options: nil)
    }
}

private struct TangemAmplitudeKey: InjectionKey {
    static var currentValue: TangemAmplitude? = {
        guard !AppEnvironment.current.isDebug else {
            return nil
        }
        return Amplitude(configuration: Configuration(apiKey: try! CommonKeysManager().amplitudeApiKey))
    }()
}

extension InjectedValues {
    var amplitude: TangemAmplitude? {
        get { Self[TangemAmplitudeKey.self] }
        set { Self[TangemAmplitudeKey.self] = newValue }
    }
}
