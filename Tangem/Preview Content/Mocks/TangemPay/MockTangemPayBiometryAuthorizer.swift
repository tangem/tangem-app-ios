//
//  MockTangemPayBiometryAuthorizer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct MockTangemPayBiometryAuthorizer: TangemPayBiometryAuthorizer {
    var isAvailable: Bool {
        true
    }

    func requestAccess() async throws {}
}
