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
    var collectionsPublisher: AnyPublisher<[NFTCollection], Never> { .just(output: []) }
    var statePublisher: AnyPublisher<NFTManagerState, Never> { .just(output: .loaded([])) }

    func update() {}
}
