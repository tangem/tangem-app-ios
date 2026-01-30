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
import Combine

final class AmplitudeWrapper {
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    static let shared: AmplitudeWrapper = .init()

    private var _amplitude: Amplitude?
    private var bag: Set<AnyCancellable> = []

    private init() {
        bind()
    }

    func configure() {
        guard !AppEnvironment.current.isDebug else {
            return
        }

        let config = Configuration(apiKey: keysManager.amplitudeApiKey)
        let amplitude = Amplitude(configuration: config)
        _amplitude = amplitude
    }

    func track(eventType: String, eventProperties: [String: Any]? = nil) {
        guard !AppEnvironment.current.isDebug else {
            return
        }

        _amplitude?.track(eventType: eventType, eventProperties: eventProperties)
    }

    private func setUserId(userId: String) {
        guard !AppEnvironment.current.isDebug else {
            return
        }

        _amplitude?.setUserId(userId: userId)
    }

    private func bind() {
        userWalletRepository
            .eventProvider
            .withWeakCaptureOf(self)
            .sink { wrapper, event in
                switch event {
                case .selected(let userWalletId):
                    wrapper.setUserId(userId: userWalletId.hashedStringValue)
                default:
                    break
                }
            }
            .store(in: &bag)
    }
}
