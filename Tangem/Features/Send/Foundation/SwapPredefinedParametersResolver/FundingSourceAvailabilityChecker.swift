//
//  FundingSourceAvailabilityChecker.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Availability for the two shapes a funding pair can take: a plain transfer of a token the
/// account itself holds, or a swap of anything else into one.
protocol FundingSourceAvailabilityChecker {
    func isTransferAvailable(walletModel: any WalletModel) -> Bool
    func isSwapAvailable(walletModel: any WalletModel) -> Bool
}

struct CommonFundingSourceAvailabilityChecker: FundingSourceAvailabilityChecker {
    private let userWalletInfo: UserWalletInfo

    init(userWalletInfo: UserWalletInfo) {
        self.userWalletInfo = userWalletInfo
    }

    /// A transfer is a plain send under the hood, so the send gates apply.
    func isTransferAvailable(walletModel: any WalletModel) -> Bool {
        makeProvider(for: walletModel).isSendAvailable
    }

    func isSwapAvailable(walletModel: any WalletModel) -> Bool {
        makeProvider(for: walletModel).isSwapAvailable
    }

    private func makeProvider(for walletModel: any WalletModel) -> TokenActionAvailabilityProvider {
        TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: walletModel)
    }
}
