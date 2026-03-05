//
//  WalletsNetworkService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletsNetworkService {
    @discardableResult
    func createWallet(with context: some Encodable) async throws -> String?

    func updateWallet(context: some Encodable) async throws
}
