//
//  DeviceRegistrationStatusRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol DeviceRegistrationStatusRepository: Sendable {
    func retrieve() -> Bool
    func persist(isRegistered: Bool)
}
