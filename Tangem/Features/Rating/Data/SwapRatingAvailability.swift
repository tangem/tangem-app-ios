//
//  SwapRatingAvailability.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SwapRatingAvailability {
    @Injected(\.keysManager) private var keysManager: KeysManager

    var isAvailable: Bool {
        let keys = keysManager.surveySparrow
        return !keys.token.isEmpty && keys.swapRating != nil
    }
}
