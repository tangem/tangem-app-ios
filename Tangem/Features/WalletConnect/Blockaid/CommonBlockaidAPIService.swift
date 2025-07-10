//
//  CommonBlockaidAPIService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils
import BlockchainSdk
import ReownWalletKit

final class CommonBlockaidAPIService: BlockaidAPIService {
    private let provider: TangemProvider<BlockaidTarget>
    private let credential: BlockaidAPICredential

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    init(provider: TangemProvider<BlockaidTarget>, credential: BlockaidAPICredential) {
        self.provider = provider
        self.credential = credential
    }

    func scanSite(url: URL) async throws -> BlockaidDTO.SiteScan.Response {
        let scanRequest = BlockaidDTO.SiteScan.Request(url: url.absoluteString)

        return try await request(target: .scanSite(request: scanRequest))
    }

    func scanEvm(
        address: String?,
        blockchain: BlockchainSdk.Blockchain,
        method: String,
        params: [AnyCodable],
        domain: URL
    ) async throws -> BlockaidDTO.EvmScan.Response {
        guard let blockchain = BlockaidDTO.Chain(blockchain: blockchain) else {
            throw BlockaidAPIServiceError.blockchainIsNotSupported
        }

        let scanRequest = BlockaidDTO.EvmScan.Request(
            accountAddress: address,
            metadata: .init(domain: domain.absoluteString),
            chain: blockchain,
            data: .init(params: params, method: method),
            block: nil
        )

        return try await request(target: .scanEvm(request: scanRequest))
    }

    func scanSolana(
        address: String,
        method: String,
        transactions: [String],
        domain: URL
    ) async throws -> BlockaidDTO.SolanaScan.Response {
        let scanRequest = BlockaidDTO.SolanaScan.Request(
            accountAddress: address,
            metadata: .init(url: domain.absoluteString),
            method: method,
            transactions: transactions
        )

        return try await request(target: .scanSolana(request: scanRequest))
    }
}

private extension CommonBlockaidAPIService {
    func request<T: Decodable>(target: BlockaidTarget.Target) async throws -> T {
        try await decoder.decode(T.self, from: request(target: target))
    }

    func request(target: BlockaidTarget.Target) async throws -> Data {
        let request = BlockaidTarget(apiKey: credential.apiKey, target: target)

        var response = try await provider.requestPublisher(request).async()

        do {
            response = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            // [REDACTED_TODO_COMMENT]

            throw error
        }

        return response.data
    }
}

// MARK: - Injected configurations and dependencies

public struct BlockaidAPICredential {
    public let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }
}

extension CommonBlockaidAPIService {
    enum BlockaidAPIServiceError: Error {
        case blockchainIsNotSupported
        case missingTransactionValue
    }
}
