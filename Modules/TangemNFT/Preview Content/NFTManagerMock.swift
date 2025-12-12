//
//  NFTManagerMock.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

public final class NFTManagerMock: NFTManager {
    public var collections: [NFTCollection] = []

    public var collectionsPublisher: AnyPublisher<NFTPartialResult<[NFTCollection]>, Never> {
        collections = switch state {
        case .failure, .loading: []
        case .success(let collections): collections.value
        }

        return Just(NFTPartialResult(value: collections))
            .eraseToAnyPublisher()
    }

    private var state: NFTManagerState
    public var statePublisher: AnyPublisher<NFTManagerState, Never> {
        Just(state)
            .eraseToAnyPublisher()
    }

    public init(state: NFTManagerState) {
        self.state = state
    }

    public func update(cachePolicy: NFTCachePolicy) {}
    public func updateAssets(in collection: NFTCollection) {}
}
