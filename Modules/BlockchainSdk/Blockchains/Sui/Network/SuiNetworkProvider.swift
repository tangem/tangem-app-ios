//
//  SuiNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import GRPC
import NIOCore
import NIOHPACK
import TangemFoundation
import TangemNetworkUtils

final class SuiNetworkProvider: HostProvider {
    var host: String {
        node.host
    }

    private static let eventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: 1)

    private let node: NodeInfo
    private let mapper = SuiGRPCMapper()
    private let connection: ClientConnection
    private let ledgerClient: Sui_Rpc_V2_LedgerServiceAsyncClient
    private let stateClient: Sui_Rpc_V2_StateServiceAsyncClient
    private let executionClient: Sui_Rpc_V2_TransactionExecutionServiceAsyncClient

    init?(node: NodeInfo, networkConfiguration: TangemProviderConfiguration) {
        self.node = node

        guard let host = node.url.host else { return nil }

        connection = ClientConnection
            .usingPlatformAppropriateTLS(for: Self.eventLoopGroup)
            .connect(host: host, port: node.url.port ?? Constants.defaultPort)

        let callOptions = Self.makeCallOptions(node: node, networkConfiguration: networkConfiguration)
        ledgerClient = Sui_Rpc_V2_LedgerServiceAsyncClient(channel: connection, defaultCallOptions: callOptions)
        stateClient = Sui_Rpc_V2_StateServiceAsyncClient(channel: connection, defaultCallOptions: callOptions)
        executionClient = Sui_Rpc_V2_TransactionExecutionServiceAsyncClient(channel: connection, defaultCallOptions: callOptions)
    }

    deinit {
        _ = connection.close()
    }

    func getCoins(address: String) -> AnyPublisher<[SuiGetCoins.Coin], Error> {
        perform(method: "StateService.ListOwnedObjects") { provider in
            var coins: [SuiGetCoins.Coin] = []
            var cursor: String?

            repeat {
                let request = try provider.mapper.makeListCoinsRequest(address: address, cursor: cursor)
                let response = try await provider.stateClient.listOwnedObjects(request)
                let page = try provider.mapper.mapToCoins(response: response)
                coins += page.data
                cursor = page.hasNextPage ? page.nextCursor : nil
            } while cursor != nil

            return coins
        }
    }

    func getBalances(address: String) -> AnyPublisher<[SuiBalance], Error> {
        perform(method: "StateService.ListBalances") { provider in
            var balances: [SuiBalance] = []
            var pageToken: Data?

            repeat {
                let request = provider.mapper.makeListBalancesRequest(address: address, pageToken: pageToken)
                let response = try await provider.stateClient.listBalances(request)
                balances += try provider.mapper.mapToBalances(response: response)
                pageToken = response.nextPageToken.isEmpty ? nil : response.nextPageToken
            } while pageToken != nil

            return balances
        }
    }

    func getServiceInfo() -> AnyPublisher<SuiServiceInfo, Error> {
        perform(method: "LedgerService.GetServiceInfo") { provider in
            let response = try await provider.ledgerClient.getServiceInfo(provider.mapper.makeGetServiceInfoRequest())
            return try provider.mapper.mapToServiceInfo(response: response)
        }
    }

    func getReferenceGasPrice() -> AnyPublisher<SuiReferenceGasPrice, Error> {
        perform(method: "LedgerService.GetEpoch") { provider in
            let response = try await provider.ledgerClient.getEpoch(provider.mapper.makeGetEpochRequest())
            return try provider.mapper.mapToReferenceGasPrice(response: response)
        }
    }

    func dryRunTransaction(transaction raw: String) -> AnyPublisher<SuiInspectTransaction, Error> {
        perform(method: "TransactionExecutionService.SimulateTransaction") { provider in
            let request = try provider.mapper.makeSimulateTransactionRequest(transaction: raw)
            let response = try await provider.executionClient.simulateTransaction(request)
            return try provider.mapper.mapToInspectTransaction(response: response)
        }
    }

    func sendTransaction(transaction raw: String, signature: String) -> AnyPublisher<SuiExecuteTransaction, Error> {
        perform(method: "TransactionExecutionService.ExecuteTransaction") { provider in
            let request = try provider.mapper.makeExecuteTransactionRequest(transaction: raw, signature: signature)
            let response = try await provider.executionClient.executeTransaction(request)
            return try provider.mapper.mapToExecuteTransaction(response: response)
        }
    }
}

// MARK: - Private

private extension SuiNetworkProvider {
    func perform<Output>(
        method: String,
        operation: @escaping @Sendable (SuiNetworkProvider) async throws -> Output
    ) -> AnyPublisher<Output, Error> {
        Future.async { [weak self] in
            guard let self else {
                throw BlockchainSdkError.empty
            }

            do {
                return try await operation(self)
            } catch {
                BSDKLogger.error("Sui gRPC \(method) failed on \(host)", error: error)
                throw error
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    static func makeCallOptions(node: NodeInfo, networkConfiguration: TangemProviderConfiguration) -> CallOptions {
        var metadata = HPACKHeaders()

        if let headers = node.headers {
            metadata.add(name: headers.headerName.lowercased(), value: headers.headerValue)
        }

        let timeout = networkConfiguration.urlSessionConfiguration.timeoutIntervalForRequest

        return CallOptions(
            customMetadata: metadata,
            timeLimit: .timeout(.seconds(Int64(timeout)))
        )
    }
}

// MARK: - Constants

private extension SuiNetworkProvider {
    enum Constants {
        static let defaultPort = 443
    }
}
