//
//  WalletManagersRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol WalletManagersRepository {
    var walletManagersPublisher: AnyPublisher<[BlockchainNetwork: any WalletManager], Never> { get }
//    func add(_ walletManager: WalletManager, for blockchainNetwork: BlockchainNetwork)
//    func remove(blockchainNetwork: BlockchainNetwork)
}
