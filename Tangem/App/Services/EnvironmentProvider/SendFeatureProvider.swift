//
//  SendFeatureProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

#warning("[REDACTED_TODO_COMMENT]")
class SendFeatureProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    static let shared: SendFeatureProvider = .init()

    var isAvailable: Bool {
        let isSendAvailableRemote = features["send"] ?? true

        return FeatureProvider.isAvailable(.sendV2) && isSendAvailableRemote
    }

    private(set) var features: [String: Bool] = [:]

    private init() {}

    func loadFeaturesAvailability() {
        runTask { [weak self] in
            guard let self else { return }

            features = (try? await tangemApiService.loadFeatures()) ?? [:]
        }
    }
}
