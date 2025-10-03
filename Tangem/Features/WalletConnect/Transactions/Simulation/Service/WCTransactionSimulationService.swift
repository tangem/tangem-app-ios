//
//  WCTransactionSimulationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import TangemLocalization

protocol WCTransactionSimulationService {
    func simulateTransaction(
        for method: WalletConnectMethod,
        address: String,
        blockchain: Blockchain,
        requestData: Data,
        domain: URL
    ) async -> TransactionSimulationState
}

final class CommonWCTransactionSimulationService: WCTransactionSimulationService {
    private let blockaidService: BlockaidAPIService
    private let decoder = JSONDecoder()
    private let simulationFailed = TransactionSimulationState.simulationFailed(
        error: Localization.wcEstimatedWalletChangesNotSimulated
    )

    init(blockaidService: BlockaidAPIService) {
        self.blockaidService = blockaidService
    }

    func simulateTransaction(
        for method: WalletConnectMethod,
        address: String,
        blockchain: Blockchain,
        requestData: Data,
        domain: URL
    ) async -> TransactionSimulationState {
        var state: TransactionSimulationState = .loading

        switch method {
        case .signTypedData, .signTypedDataV4:
            state = await handleEIP712Simulation(
                method: method.rawValue,
                address: address,
                blockchain: blockchain,
                data: requestData,
                domain: domain
            )

        case .sendTransaction, .signTransaction:
            state = await handleEthTransactionSimulation(
                method: method,
                address: address,
                blockchain: blockchain,
                data: requestData,
                domain: domain
            )

        case .solanaSignTransaction, .solanaSignAllTransactions:
            state = await handleSolanaTransactionSimulation(
                method: method,
                address: address,
                blockchain: blockchain,
                data: requestData,
                domain: domain
            )

        default:
            state = .simulationNotSupported(method: method.rawValue)
        }

        return state
    }

    private func handleEIP712Simulation(
        method: String,
        address: String,
        blockchain: Blockchain,
        data: Data,
        domain: URL
    ) async -> TransactionSimulationState {
        do {
            guard let messageString = String(data: data, encoding: .utf8) else {
                return simulationFailed
            }

            let response = try await blockaidService.scanEvm(
                address: address,
                blockchain: blockchain,
                method: method,
                params: [.init(address), .init(messageString)],
                domain: domain
            )

            let result = try BlockaidMapper.mapBlockchainScan(response)

            return .simulationSucceeded(result: result)

        } catch {
            return simulationFailed
        }
    }

    private func handleEthTransactionSimulation(
        method: WalletConnectMethod,
        address: String,
        blockchain: Blockchain,
        data: Data,
        domain: URL
    ) async -> TransactionSimulationState {
        do {
            guard let transaction = try? decoder.decode(WalletConnectEthTransaction.self, from: data) else {
                return simulationFailed
            }

            let transactionParams = BlockaidDTO.TransactionParams(
                from: transaction.from,
                to: transaction.to,
                data: transaction.data ?? "0x",
                value: transaction.value ?? "0x0"
            )

            let response = try await blockaidService.scanEvm(
                address: transaction.from,
                blockchain: blockchain,
                method: method.rawValue,
                params: [.init(transactionParams)],
                domain: domain
            )

            let result = try BlockaidMapper.mapBlockchainScan(response)

            return .simulationSucceeded(result: result)

        } catch {
            return simulationFailed
        }
    }

    private func handleSolanaTransactionSimulation(
        method: WalletConnectMethod,
        address: String,
        blockchain: Blockchain,
        data: Data,
        domain: URL
    ) async -> TransactionSimulationState {
        do {
            let transactions = try decoder.decode([String].self, from: data)

            let response = try await blockaidService.scanSolana(
                address: address.base58DecodedData.base64EncodedString(),
                method: method.trimmedPrefixValue,
                transactions: transactions,
                domain: domain
            )

            let result = BlockaidMapper.mapBlockchainScan(response)
            return .simulationSucceeded(result: result)

        } catch {
            return simulationFailed
        }
    }
}
