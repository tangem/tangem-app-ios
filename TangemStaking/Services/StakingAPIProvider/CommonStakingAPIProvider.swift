//
//  CommonStakingAPIProvider.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class CommonStakingAPIProvider: StakingAPIProvider {
    let service: StakingAPIService
    let mapper: StakeKitMapper

    init(service: StakingAPIService, mapper: StakeKitMapper) {
        self.service = service
        self.mapper = mapper
    }

    func enabledYields() async throws -> [YieldInfo] {
        let response = try await service.enabledYields()
        let yieldInfos = try response.data.map(mapper.mapToYieldInfo(from:))
        return yieldInfos
    }

    func yield(integrationId: String) async throws -> YieldInfo {
        let response = try await service.getYield(request: .init(integrationId: integrationId))
        let yieldInfo = try mapper.mapToYieldInfo(from: response)
        return yieldInfo
    }

    func balances(wallet: StakingWallet) async throws -> [StakingBalanceInfo]? {
        assert(StakeKitDTO.NetworkType(rawValue: wallet.item.coinId) != nil, "NetworkType not found")

        let request = StakeKitDTO.Balances.Request(addresses: .init(address: wallet.address), network: wallet.item.coinId)
        let response = try await service.getBalances(request: request)
        let balancesInfo = try mapper.mapToBalanceInfo(from: response)
        return balancesInfo
    }

    func enterAction(amount: Decimal, address: String, validator: String, integrationId: String) async throws -> EnterAction {
        let request = StakeKitDTO.Actions.Enter.Request(
            integrationId: integrationId,
            addresses: .init(address: address),
            args: .init(amount: amount.description, validatorAddress: validator, validatorAddresses: [.init(address: validator)])
        )

        let response = try await service.enterAction(request: request)
        let enterAction = try mapper.mapToEnterAction(from: response)
        return enterAction
    }

    func exitAction(amount: Decimal, address: String, validator: String, integrationId: String) async throws -> ExitAction {
        let request = StakeKitDTO.Actions.Exit.Request(
            integrationId: integrationId,
            addresses: .init(address: address),
            args: .init(amount: amount.description, validatorAddress: validator)
        )

        let response = try await service.exitAction(request: request)
        let enterAction = try mapper.mapToExitAction(from: response)
        return enterAction
    }

    func pendingAction() async throws {
        // [REDACTED_TODO_COMMENT]
    }

    func transaction(id: String) async throws -> StakingTransactionInfo {
        let response = try await service.transaction(id: id)
        let transactionInfo = try mapper.mapToTransactionInfo(from: response)
        return transactionInfo
    }

    func patchTransaction(id: String) async throws -> StakingTransactionInfo {
        let response = try await service.constructTransaction(id: id, request: .init(gasArgs: .none))
        let transactionInfo = try mapper.mapToTransactionInfo(from: response)
        return transactionInfo
    }

    func submitTransaction(hash: String, signedTransaction: String) async throws {
        _ = try await service.submitTransaction(id: hash, request: .init(signedTransaction: signedTransaction))
    }

    func submitHash(hash: String, transactionId: String) async throws {
        _ = try await service.submitHash(id: transactionId, request: .init(hash: hash))
    }
}
