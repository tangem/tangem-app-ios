//
//  CommonCollectiblesVaultReader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles

final class CommonCollectiblesVaultReader {
    private let serviceProvider: CollectiblesChainServiceProvider

    init(serviceProvider: CollectiblesChainServiceProvider = CollectiblesChainServiceProvider()) {
        self.serviceProvider = serviceProvider
    }
}

// MARK: - CollectiblesVaultReader protocol conformance

extension CommonCollectiblesVaultReader: CollectiblesVaultReader {
    func vaultInfo(coldOwner: Data) async throws -> CollectiblesVaultInfo? {
        let program = try CollectiblesVaultProgram(programId: CollectiblesChainEnvironment.programId)
        let vaultAddress = try program.vaultAddress(coldOwner: coldOwner)

        guard let account = try await serviceProvider.service().account(address: vaultAddress) else {
            return nil
        }

        do {
            return try program.vaultInfo(coldOwner: coldOwner, accountOwner: account.owner, accountData: account.data)
        } catch {
            // The refresh swallows what it gets back, so a rejected account is only visible from here
            AppLogger.error("Collectibles vault account rejected", error: error)
            throw error
        }
    }
}
