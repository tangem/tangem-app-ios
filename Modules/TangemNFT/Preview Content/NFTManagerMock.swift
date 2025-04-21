//
//  NFTManagerMock.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class NFTManagerMock: NFTManager {
    var collections: [NFTCollection] = []

    var collectionsPublisher: AnyPublisher<[NFTCollection], Never> {
        Just([]).eraseToAnyPublisher()
    }

    private var state: NFTManagerState
    var statePublisher: AnyPublisher<NFTManagerState, Never> {
        Just(state)
            .eraseToAnyPublisher()
    }

    init(state: NFTManagerState) {
        self.state = state
    }

    func update() {}
}
