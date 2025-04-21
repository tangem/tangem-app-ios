//
//  NFTManager.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

public typealias NFTManagerState = LoadingValue<[NFTCollection]>

public protocol NFTManager {
    var collections: [NFTCollection] { get }
    var collectionsPublisher: AnyPublisher<[NFTCollection], Never> { get }
    var statePublisher: AnyPublisher<NFTManagerState, Never> { get }

    func update()
}
