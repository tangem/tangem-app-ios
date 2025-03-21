//
//  NFTAvailabilityProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol NFTAvailabilityProvider {
    var didChangeNFTAvailabilityPublisher: AnyPublisher<Void, Never> { get }

    func isNFTAvailable(for userWalletModel: UserWalletModel) -> Bool
    func isNFTEnabled(forUserWalletWithId userWalletId: UserWalletId) -> Bool
    func setNFTEnabled(_ enabled: Bool, forUserWalletWithId userWalletId: UserWalletId)
}

// MARK: - Convenience extensions

extension NFTAvailabilityProvider {
    func isNFTEnabled(for userWalletModel: UserWalletModel) -> Bool {
        return isNFTEnabled(forUserWalletWithId: userWalletModel.userWalletId)
    }

    func setNFTEnabled(_ enabled: Bool, for userWalletModel: UserWalletModel) {
        setNFTEnabled(enabled, forUserWalletWithId: userWalletModel.userWalletId)
    }
}
