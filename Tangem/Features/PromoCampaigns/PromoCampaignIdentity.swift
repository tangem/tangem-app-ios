//
//  PromoCampaignIdentity.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PromoCampaignIdentity: Hashable {
    case card(batchId: String)
    case mobile
}

protocol PromoCampaignIdentityProviding {
    var promoCampaignIdentity: PromoCampaignIdentity { get }
}
