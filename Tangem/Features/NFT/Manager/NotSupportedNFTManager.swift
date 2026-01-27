//
//  NotSupportedNFTManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemNFT

struct NotSupportedNFTManager: NFTManager {
    var collections: [NFTCollection] { [] }
    var collectionsPublisher: AnyPublisher<NFTPartialResult<[NFTCollection]>, Never> { .just(output: []) }
    var statePublisher: AnyPublisher<NFTManagerState, Never> { .just(output: .success([])) }

    func update(cachePolicy: NFTCachePolicy) {}
    func updateAssets(in collection: NFTCollection) {}
}
