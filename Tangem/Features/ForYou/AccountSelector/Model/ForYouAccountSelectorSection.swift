//
//  ForYouAccountSelectorSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

/// One wallet's crypto accounts as shown in the For You multi-account selector.
struct ForYouAccountSelectorSection: Identifiable {
    let walletId: String
    let walletName: String
    let walletThumbnailType: ThumbnailWalletViewType?
    let accounts: [Item]

    var id: String { walletId }

    struct Item: Identifiable {
        let id: ForYouAccountID
        let rowViewModel: AccountRowButtonViewModel
    }
}
