//
//  GachaAccountStatusMockProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct GachaAccountStatusMockProvider: GachaAccountStatusProvider {
    func load() async throws -> GachaAccountStatus {
        try await Task.sleep(for: .seconds(1))
        return .missing
    }
}
