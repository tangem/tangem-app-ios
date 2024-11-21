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
        let response = try await service.getYield(id: integrationId, request: .init())
        let yieldInfo = try mapper.mapToYieldInfo(from: response)
        return yieldInfo
    }

    func balances(wallet: StakingWallet) async throws -> [StakingBalanceInfo] {
        let request = StakeKitDTO.Balances.Request(
            addresses: .init(address: wallet.address),
            network: wallet.item.network
        )
        let response = try await service.getBalances(request: request)
        let balancesInfo = try mapper.mapToBalanceInfo(from: response)
        return balancesInfo
    }

    func actions(wallet: StakingWallet) async throws -> [PendingAction] {
        let request = StakeKitDTO.Actions.List.Request(
            walletAddress: wallet.address,
            network: wallet.item.network,
            status: .processing,
            limit: Constants.pendingActionsResponseLimit,
            sort: Constants.pendingActionsResponseSort
        )
        let response = try await service.actions(request: request)
        return try mapper.mapToPendingActions(from: response)
    }

    func estimateStakeFee(request: ActionGenericRequest) async throws -> Decimal {
        let request = mapper.mapToEnterRequest(request: request)
        let response = try await service.estimateGasEnterAction(request: request)

        guard let result = Decimal(stringValue: response.amount) else {
            throw StakeKitMapperError.noData("EnterAction fee not found")
        }

        return result
    }

    func estimateUnstakeFee(request: ActionGenericRequest) async throws -> Decimal {
        let request = mapper.mapToExitRequest(request: request)
        let response = try await service.estimateGasExitAction(request: request)

        guard let result = Decimal(stringValue: response.amount) else {
            throw StakeKitMapperError.noData("ExitAction fee not found")
        }

        return result
    }

    func estimatePendingFee(request: PendingActionRequest) async throws -> Decimal {
        let request = mapper.mapToPendingRequest(request: request)
        let response = try await service.estimateGasPendingAction(request: request)

        guard let result = Decimal(stringValue: response.amount) else {
            throw StakeKitMapperError.noData("PendingAction fee not found")
        }

        return result
    }

    func enterAction(request: ActionGenericRequest) async throws -> EnterAction {
        let request = mapper.mapToEnterRequest(request: request)
        let response = try await service.enterAction(request: request)
        let enterAction = try mapper.mapToEnterAction(from: response)
        return enterAction
    }

    func exitAction(request: ActionGenericRequest) async throws -> ExitAction {
        let request = mapper.mapToExitRequest(request: request)
        let response = try await service.exitAction(request: request)
        let enterAction = try mapper.mapToExitAction(from: response)
        return enterAction
    }

    func pendingAction(request: PendingActionRequest) async throws -> PendingAction {
        let request = mapper.mapToPendingRequest(request: request)
        let response = try await service.pendingAction(request: request)
        let enterAction = try mapper.mapToPendingAction(from: response)
        return enterAction
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
        try await service.submitHash(id: transactionId, request: .init(hash: hash))
    }
}

extension CommonStakingAPIProvider {
    enum Constants {
        static let pendingActionsResponseLimit = 50 // maximum that supports stakekit API
        static let pendingActionsResponseSort = "createdAtDesc"
    }
}
