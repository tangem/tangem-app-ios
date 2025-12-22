//
//  TokenItemPromoBubbleVisibilityInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class TokenItemPromoBubbleVisibilityInteractor {
    // MARK: - Services

    @AppStorageCompat(StorageKeys.dismissedTokenItemPromoBubbles)
    private var dismissedPromoBubbles: [String: Bool] = [:]

    // MARK: - Public Implementation

    func shouldShowPromoBubble(for promoKey: String) -> Bool {
        let objectRepresentable = makeObjectKey(from: promoKey)
        let dismissed = dismissedPromoBubbles[objectRepresentable] ?? false
        return !dismissed
    }

    func markPromoBubbleDismissed(for promoKey: String) {
        let objectRepresentable = makeObjectKey(from: promoKey)
        dismissedPromoBubbles[objectRepresentable] = true
    }

    // MARK: - Private Implementation

    private func makeObjectKey(from promoKey: String) -> String {
        "\(StorageKeys.dismissedTokenItemPromoBubbles)_\(promoKey)"
    }
}

extension TokenItemPromoBubbleVisibilityInteractor {
    enum StorageKeys: String, RawRepresentable {
        case dismissedTokenItemPromoBubbles = "main_dismissed_token_item_promo_bubble"
    }
}
