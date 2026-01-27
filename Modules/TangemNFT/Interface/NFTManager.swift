//
//  NFTManager.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

public typealias NFTManagerState = LoadingResult<NFTPartialResult<[NFTCollection]>, any Error>

public protocol NFTManager {
    var collections: [NFTCollection] { get }
    var collectionsPublisher: AnyPublisher<NFTPartialResult<[NFTCollection]>, Never> { get }
    var statePublisher: AnyPublisher<NFTManagerState, Never> { get }

    func update(cachePolicy: NFTCachePolicy)
    func updateAssets(in collection: NFTCollection)
}
