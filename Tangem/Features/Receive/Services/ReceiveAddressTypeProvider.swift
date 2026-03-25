//
//  ReceiveAddressTypeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// MARK: - Receive Addresses

protocol ReceiveAddressTypesProvider {
    var receiveAddressTypesPublisher: AnyPublisher<[ReceiveAddressType], Never> { get }
}
