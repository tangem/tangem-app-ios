//
//  AppAttestation+fake.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import TangemBackendAuthentication

extension AppAttestation {
    static let fake = AppAttestation(keyID: "any-app-attest-key", object: Data("any-app-attest-object".utf8))
}
