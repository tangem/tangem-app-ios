//
//  HotCryptoAddToPortfolioBottomSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

struct HotCryptoAddToPortfolioBottomSheetViewModel: Identifiable {
    let id = UUID()
    let token: HotCryptoToken
    let userWalletName: String
    let tokenNetworkName: String
    let mainButtonIcon: MainButton.Icon?
    let tokenIconInfo: TokenIconInfo?
    let action: () -> Void

    init(token: HotCryptoToken, userWalletName: String, tangemIconProvider: TangemIconProvider, action: @escaping () -> Void) {
        self.token = token
        self.userWalletName = userWalletName
        tokenIconInfo = token.tokenIconInfo
        tokenNetworkName = token.tokenItem?.blockchain.displayName ?? ""
        mainButtonIcon = tangemIconProvider.getMainButtonIcon()
        self.action = action
    }
}
