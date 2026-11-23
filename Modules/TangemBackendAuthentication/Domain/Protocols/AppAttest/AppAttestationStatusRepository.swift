//
//  AppAttestationStatusRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

package protocol AppAttestationStatusRepository: Sendable {
    func retrieve() -> Bool
    func persist(isAppAttested: Bool)
}
