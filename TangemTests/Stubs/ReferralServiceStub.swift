//
//  ReferralServiceStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
@testable import Tangem

final class ReferralServiceStub: ReferralService {
    private let state: OSAllocatedUnfairLock<State>

    init(refcode: String? = nil, campaign: String? = nil) {
        state = OSAllocatedUnfairLock(initialState: State(refcode: refcode, campaign: campaign))
    }

    var refcode: String? { state.withLock { ReferralParam.normalized($0.refcode) } }

    var campaign: String? { state.withLock { ReferralParam.normalized($0.campaign) } }

    var hasNoReferral: Bool { refcode == nil }

    var saveCallsCount: Int { state.withLock { $0.saveCallsCount } }

    func saveAndBindIfNeeded(refcode: String, campaign: String?) {
        state.withLock { state in
            guard ReferralParam.normalized(state.refcode) == nil else {
                return
            }

            state.refcode = refcode
            state.campaign = campaign
            state.saveCallsCount += 1
        }
    }

    func retryBindingIfNeeded() {}
}

private extension ReferralServiceStub {
    struct State {
        var refcode: String?
        var campaign: String?
        var saveCallsCount: Int = 0
    }
}
