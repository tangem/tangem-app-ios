//
//  BlockaidAPIService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils
import BlockchainSdk

protocol BlockaidAPIService {
    func scanSite(url: URL) async throws -> BlockaidDTO.SiteScan.Response
    func scanEvm(
        address: String?,
        blockchain: Blockchain,
        method: String,
        transaction: WalletConnectEthTransaction,
        domain: URL
    ) async throws -> BlockaidDTO.ScanBlockchainResponse
    
    func scanSolana(
        address: String,
        method: String,
        transaction: WalletConnectSolanaSignMessageDTO.Body,
        domain: URL
    ) async throws -> BlockaidDTO.ScanBlockchainResponse
}

final class CommonBlockaidAPIService: BlockaidAPIService {
    private let provider: MoyaProvider<BlockaidTarget>
    private let credential: BlockaidAPICredential

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }()

    init(provider: MoyaProvider<BlockaidTarget>, credential: BlockaidAPICredential) {
        self.provider = provider
        self.credential = credential
    }

    func scanSite(url: URL) async throws -> BlockaidDTO.SiteScan.Response {
        let scanRequest = BlockaidDTO.SiteScan.Request(url: url.absoluteString)

        return try await request(target: .scanSite(request: scanRequest))
    }

    func scanEvm(
        address: String?,
        blockchain: Blockchain,
        method: String,
        transaction: WalletConnectEthTransaction,
        domain: URL
    ) async throws -> BlockaidDTO.ScanBlockchainResponse {
        guard let blockchain = BlockaidDTO.Chain(blockchain: blockchain) else { fatalError() }

        let params = BlockaidDTO.EvmScan.Request.Params(
            from: transaction.from,
            to: transaction.to,
            data: transaction.data,
            value: transaction.value! // [REDACTED_TODO_COMMENT]
        )

        let scanRequest = BlockaidDTO.EvmScan.Request(
            accountAddress: address,
            metadata: .init(domain: domain.absoluteString),
            chain: blockchain,
            data: .init(params: [params], method: method),
            block: nil
        )

        return try await request(target: .scanEvm(request: scanRequest))
    }
    
    func scanSolana(
        address: String,
        method: String,
        transaction: WalletConnectSolanaSignMessageDTO.Body,
        domain: URL
    ) async throws -> BlockaidDTO.ScanBlockchainResponse {
        let scanRequest = BlockaidDTO.SolanaScan.Request(
            accountAddress: address,
            metadata: .init(domain: domain.absoluteString),
            method: method,
            transactions: [transaction.signature]
        )
    }
}

private extension CommonBlockaidAPIService {
    func request<T: Decodable>(target: BlockaidTarget.Target) async throws -> T {
        return try await decoder.decode(T.self, from: request(target: target).data)
    }

    func request(target: BlockaidTarget.Target) async throws -> Moya.Response {
        let request = BlockaidTarget(apiKey: credential.apiKey, target: target)
        var response = try await provider.requestPublisher(request).async()

        do {
            response = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            // [REDACTED_TODO_COMMENT]

            throw error
        }

        return response
    }
}

// MARK: - Injected configurations and dependencies

public struct BlockaidAPICredential {
    public let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }
}
