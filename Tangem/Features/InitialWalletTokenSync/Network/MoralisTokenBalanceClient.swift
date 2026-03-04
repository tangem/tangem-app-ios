//
//  MoralisTokenBalanceClient.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Moya
import BlockchainSdk
import TangemNetworkUtils

protocol MoralisTokenBalanceClient {
    func getTokenBalances(network: Blockchain, address: String) async throws -> [MoralisTokenBalance]
}

final class CommonMoralisTokenBalanceClient {
    @Injected(\.keysManager) private var keysManager: KeysManager

    private let customProvider: TangemProvider<MoralisTokenBalanceAPITarget>?
    private let chainMapper = MoralisChainMapper()

    private lazy var provider: TangemProvider<MoralisTokenBalanceAPITarget> = {
        if let customProvider {
            return customProvider
        }

        let headers = [
            APIHeaderKeyInfo(
                headerName: Constants.xAPIKeyHeaderName,
                headerValue: keysManager.moralisAPIKey
            ),
        ]

        return TangemProvider(
            configuration: .ephemeralConfiguration,
            additionalPlugins: [NetworkHeadersPlugin(networkHeaders: headers)]
        )
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    init(provider: TangemProvider<MoralisTokenBalanceAPITarget>? = nil) {
        customProvider = provider
    }
}

extension CommonMoralisTokenBalanceClient: MoralisTokenBalanceClient {
    func getTokenBalances(network: Blockchain, address: String) async throws -> [MoralisTokenBalance] {
        let chain = try chainMapper.map(blockchain: network)

        do {
            let response = try await provider.asyncRequest(
                MoralisTokenBalanceAPITarget(
                    target: .tokenBalances(address: address, chain: chain)
                )
            )

            let dto = try response
                .filterSuccessfulStatusCodes()
                .map(MoralisTokenBalanceDTO.Response.self, using: decoder)

            return try MoralisTokenBalanceNormalizer.normalize(dto.result)
        } catch let error as MoralisTokenBalanceError {
            throw error
        } catch let error as DecodingError {
            throw MoralisTokenBalanceError.decoding(error)
        } catch let error as MoralisTokenBalanceNormalizer.NormalizationError {
            throw MoralisTokenBalanceError.decoding(error)
        } catch {
            throw MoralisTokenBalanceError.network(error)
        }
    }
}

private extension CommonMoralisTokenBalanceClient {
    enum Constants {
        static let xAPIKeyHeaderName = "X-API-KEY"
    }
}
