//
//  PromoCampaignEnrollmentWallet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct PromoCampaignEnrollmentWallet {
    let name: String
    let subtitle: String
    let imageProvider: WalletImageProviding
    let payout: Payout?
}

extension PromoCampaignEnrollmentWallet {
    struct Payout {
        let address: String
    }
}
