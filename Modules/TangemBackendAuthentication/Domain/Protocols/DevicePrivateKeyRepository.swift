//
//  DevicePrivateKeyRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol DevicePrivateKeyRepository<Key>: Sendable {
    associatedtype Key: DevicePrivateKey

    func retrieve() async throws(DevicePrivateKeyRepositoryError) -> Key
    func delete() async throws(DevicePrivateKeyRepositoryError)
}
