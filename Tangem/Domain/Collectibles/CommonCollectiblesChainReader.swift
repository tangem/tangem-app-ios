//
//  CommonCollectiblesChainReader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles

final class CommonCollectiblesChainReader {
    private let serviceProvider: CollectiblesChainServiceProvider

    init(serviceProvider: CollectiblesChainServiceProvider = CollectiblesChainServiceProvider()) {
        self.serviceProvider = serviceProvider
    }
}

// MARK: - CollectiblesVaultReader protocol conformance

extension CommonCollectiblesChainReader: CollectiblesVaultReader {
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
            CollectiblesLogger.error("Vault account rejected", error: error)
            throw error
        }
    }
}

// MARK: - CollectiblesConfigReader protocol conformance

extension CommonCollectiblesChainReader: CollectiblesConfigReader {
    func configInfo() async throws -> CollectiblesConfigInfo {
        let program = try CollectiblesVaultProgram(programId: CollectiblesChainEnvironment.programId)
        let configAddress = try program.configAddress()

        guard let account = try await serviceProvider.service().account(address: configAddress) else {
            throw ReadError.configMissing
        }

        return try program.configInfo(accountOwner: account.owner, accountData: account.data)
    }
}

// MARK: - CollectiblesVaultUsdcReader protocol conformance

extension CommonCollectiblesChainReader: CollectiblesVaultUsdcReader {
    func usdcBalance(coldOwner: Data) async throws -> UInt64 {
        let program = try CollectiblesVaultProgram(programId: CollectiblesChainEnvironment.programId)
        let usdcMint = try await configInfo().usdcMint
        let address = try program.vaultUsdcAddress(coldOwner: coldOwner, usdcMint: usdcMint)

        guard let account = try await serviceProvider.service().account(address: address) else {
            return 0
        }

        return try program.vaultUsdcBalance(
            coldOwner: coldOwner,
            usdcMint: usdcMint,
            accountOwner: account.owner,
            accountData: account.data
        )
    }
}

// MARK: - Private implementation

private extension CommonCollectiblesChainReader {
    enum ReadError: Error {
        case configMissing
    }
}
