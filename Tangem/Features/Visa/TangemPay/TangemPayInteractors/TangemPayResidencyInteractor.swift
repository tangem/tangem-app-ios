//
//  TangemPayResidencyInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayResidencyInteractor: TangemPayKYCInteractor {
    var waitlistService: TangemPayWaitlistService { get }

    func beginResidency()
    func completeResidency(_ result: TangemPayResidencyResult)
    func hideAccountFromHome()
}

enum TangemPayResidencyResult {
    case eligible
    case unavailable(TangemPayUnavailableRegion)
}
