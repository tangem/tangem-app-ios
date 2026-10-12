//
//  ReferralDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// `tangem://referral[?user_wallet_id]`
struct ReferralDeeplink: HostNamedDeeplink, Equatable {
    static let host = "referral"

    let userWalletId: String?

    var action: DeeplinkNavigationAction { .referral(self) }
}

// MARK: - Parsing

extension ReferralDeeplink {
    init(link: DeeplinkURL) throws {
        try link.query.validate(Shared.tokenId, Shared.networkId, Shared.promoCode)

        userWalletId = link.query.unchecked(Shared.userWalletId)
    }
}

// MARK: - Navigation

extension ReferralDeeplink {
    @MainActor
    func makeInput() -> ReferralInputModel? {
        guard let userWalletModel = DeeplinkWalletModelLocator().findUserWalletModel(
            userWalletModelId: userWalletId,
            requiring: .referralProgram
        ) else {
            return nil
        }

        return ReferralInputModel(
            userWalletId: userWalletModel.userWalletId.value,
            supportedBlockchains: userWalletModel.config.supportedBlockchains,
            accountModelsManager: userWalletModel.accountModelsManager,
            tokenIconInfoBuilder: TokenIconInfoBuilder(),
            userWalletModel: userWalletModel
        )
    }
}
