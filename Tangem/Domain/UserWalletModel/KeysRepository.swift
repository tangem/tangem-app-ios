//
//  KeysRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol KeysRepository: AnyObject, KeysProvider {
    func update(keys: [WalletPublicInfo])
}

protocol KeysProvider {
    var keys: [WalletPublicInfo] { get }
    var keysPublisher: AnyPublisher<[WalletPublicInfo], Never> { get }
}

class CommonKeysRepository {
    private var _keys: CurrentValueSubject<[WalletPublicInfo], Never>

    init(with keys: [WalletPublicInfo]) {
        _keys = .init(keys)
    }
}

extension CommonKeysRepository: KeysRepository {
    var keys: [WalletPublicInfo] {
        _keys.value
    }

    var keysPublisher: AnyPublisher<[WalletPublicInfo], Never> {
        _keys.eraseToAnyPublisher()
    }

    func update(keys: [WalletPublicInfo]) {
        _keys.value = keys
    }
}
