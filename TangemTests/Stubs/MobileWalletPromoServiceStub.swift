//
//  MobileWalletPromoServiceStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
@testable import Tangem

final class MobileWalletPromoServiceStub: MobileWalletPromoService {
    private let state = OSAllocatedUnfairLock(initialState: false)

    var shouldShowMobilePromoWalletSelector: Bool { state.withLock { $0 } }

    func setNeedsPromo() {
        state.withLock { $0 = true }
    }
}
