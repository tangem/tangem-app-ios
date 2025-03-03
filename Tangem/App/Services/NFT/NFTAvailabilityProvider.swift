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
    func isNFTEnabled(for userWalletModel: UserWalletModel) -> Bool
    func setNFTEnabled(_ enabled: Bool, for userWalletModel: UserWalletModel)
}
