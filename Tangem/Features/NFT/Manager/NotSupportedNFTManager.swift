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
    var collectionsPublisher: AnyPublisher<NFTPartialResult<[NFTCollection]>, Never> { .just(output: NFTPartialResult(value: [])) }
    var statePublisher: AnyPublisher<NFTManagerState, Never> { .just(output: .loaded(NFTPartialResult(value: []))) }

    func update() {}
    func updateAssets(inCollectionWithIdentifier collectionIdentifier: NFTCollection.ID) {}
}
