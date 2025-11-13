//
//  UserTokensRepositoryBatchUpdater.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class UserTokensRepositoryBatchUpdater {
    private(set) var updates: [UserTokenListUpdateType] = []

    func append(_ entries: [TokenItem]) {
        updates.append(.append(entries))
    }

    func remove(_ entry: TokenItem) {
        updates.append(.remove(entry))
    }

    func update(_ request: UserTokensRepositoryUpdateRequest) {
        updates.append(.update(request))
    }
}
