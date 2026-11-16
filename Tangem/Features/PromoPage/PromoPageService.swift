//
//  PromoPageService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct PromoPageService {
    @Injected(\.promoPageStorage) private var storage: PromoPageStorage

    private let isEnabled: Bool

    init(isEnabled: Bool = FeatureProvider.isAvailable(.promoPage)) {
        self.isEnabled = isEnabled
    }

    var pendingPage: String? {
        storage.pendingPage
    }

    func markPending(page: String) {
        storage.pendingPage = isEnabled ? page : nil
    }

    func clearPending() {
        storage.pendingPage = nil
    }
}
