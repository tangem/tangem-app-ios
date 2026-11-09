//
//  MarketingActivityBindingService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketingActivityBindingService: Initializable {
    func register(uid: String)
}

extension InjectedValues {
    var marketingActivityBindingService: MarketingActivityBindingService {
        get { Self[MarketingActivityBindingServiceKey.self] }
        set { Self[MarketingActivityBindingServiceKey.self] = newValue }
    }
}

private struct MarketingActivityBindingServiceKey: InjectionKey {
    static var currentValue: MarketingActivityBindingService = {
        guard FeatureProvider.isAvailable(.marketingActivityBinding) else {
            return DummyMarketingActivityBindingService()
        }

        return CommonMarketingActivityBindingService()
    }()
}

private struct DummyMarketingActivityBindingService: MarketingActivityBindingService {
    func initialize() {}
    func register(uid: String) {}
}
