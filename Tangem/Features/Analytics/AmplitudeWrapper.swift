//
//  AmplitudeWrapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation
import AmplitudeSwift
import TangemSdk

final class AmplitudeWrapper {
    @Injected(\.keysManager) private var keysManager: KeysManager

    static let shared: AmplitudeWrapper = .init()

    private var _amplitude: Amplitude?

    private init() {}

    func configure() {
        let config = Configuration(apiKey: keysManager.amplitudeApiKey)
        let amplitude = Amplitude(configuration: config)
        _amplitude = amplitude
    }

    func setUserId(userId: UserWalletId) {
        let id = userId.value.sha256().hexString
        _amplitude?.setUserId(userId: id)
    }

    func track(eventType: String, eventProperties: [String: Any]? = nil) {
        _amplitude?.track(eventType: eventType, eventProperties: eventProperties)
    }
}
