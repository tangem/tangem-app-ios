//
//  CryptoAccountsAuxiliaryDataStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol CryptoAccountsAuxiliaryDataStorage {
    var didChangePublisher: AnyPublisher<Void, Never> { get }
    var archivedAccountsCount: Int { get nonmutating set }
    var totalAccountsCount: Int { get nonmutating set }
}
