//
//  PersistentStorageProtocol.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol PersistentStorageProtocol {
    func value<T: Decodable>(for key: PersistentStorageKey) throws -> T?
    func store<T: Encodable>(value: T, for key: PersistentStorageKey) throws
}

private struct PersistentStorageProtocolKey: InjectionKey {
    static var currentValue: PersistentStorageProtocol = PersistentStorage()
}

extension InjectedValues {
    var persistentStorage: PersistentStorageProtocol {
        get { Self[PersistentStorageProtocolKey.self] }
        set { Self[PersistentStorageProtocolKey.self] = newValue }
    }
}
