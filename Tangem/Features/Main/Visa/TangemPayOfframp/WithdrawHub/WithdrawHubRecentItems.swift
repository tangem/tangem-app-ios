//
//  WithdrawHubRecentItems.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAccounts
import TangemAssets
import TangemUI

struct WithdrawHubRecentTokenItem: Identifiable {
    let id: String
    let tokenIconInfo: TokenIconInfo
    let name: String
    let accountIcon: AccountIconView.ViewData
    let accountName: String
}

struct WithdrawHubRecentAccountItem: Identifiable {
    let id: String
    let monogram: String
    let name: String
    let accountNumber: String
}

// MARK: - Previews

#if DEBUG
extension WithdrawHubRecentTokenItem {
    static let preview = WithdrawHubRecentTokenItem(
        id: "polygon",
        tokenIconInfo: .remote(name: "Polygon", imageURL: nil),
        name: "Polygon",
        accountIcon: .composite(backgroundColor: .blue, nameMode: .imageType(Assets.Accounts.starAccounts)),
        accountName: "Main account"
    )
}

extension WithdrawHubRecentAccountItem {
    static let preview = WithdrawHubRecentAccountItem(
        id: "pablo",
        monogram: "P",
        name: "Pablo E",
        accountNumber: "0000000000"
    )
}
#endif
