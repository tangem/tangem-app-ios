//
//  PromoCampaignsAvailability.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PromoCampaignsAvailability {
    static var isEnabled: Bool {
        FeatureProvider.isAvailable(.promoCampaignsV2)
    }
}
