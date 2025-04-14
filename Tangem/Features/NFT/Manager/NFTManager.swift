//
//  NFTManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemNFT

protocol NFTManager {
    var collections: [NFTCollection] { get }
    var collectionsPublisher: AnyPublisher<[NFTCollection], Never> { get }
    var statePublisher: AnyPublisher<NFTManagerState, Never> { get }

    func update()
}
