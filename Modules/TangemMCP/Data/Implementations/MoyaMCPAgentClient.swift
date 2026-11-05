//
//  MoyaMCPAgentClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import enum Moya.MoyaError
import class Moya.MoyaProvider
import class Moya.Response
private import TangemNetworkUtils

struct MoyaMCPAgentClient: MCPAgentClient {
    private let provider: MoyaProvider<MCPClientTarget>
    private let baseURL: URL
    private let decoder: JSONDecoder

    init(provider: MoyaProvider<MCPClientTarget>, baseURL: URL, decoder: JSONDecoder) {
        self.provider = provider
        self.baseURL = baseURL
        self.decoder = decoder
    }

    func fetch(agentID: String) async throws(MCPAgentClientError) -> MCPAgent {
        let target = MCPClientTarget.get(agentID: agentID, baseURL: baseURL)

        let response: Moya.Response
        do {
            response = try await provider.request(target)
        } catch {
            throw wrapped(moyaError: error, into: MCPAgentClientError.fetchFailed)
        }

        do {
            let fetchResponse = try decoder.decode(MCPClientDTO.Get.Response.self, from: response.data)
            return MCPAgentMapper.mapToDomain(fetchResponse)
        } catch {
            throw MCPAgentClientError.fetchFailed(underlying: error)
        }
    }
}

extension MoyaMCPAgentClient {
    private func wrapped(
        moyaError: MoyaError,
        into agentClientError: (any Error) -> MCPAgentClientError
    ) -> MCPAgentClientError {
        guard let problemDetailError = parseProblemDetail(from: moyaError.response?.data) else {
            return agentClientError(moyaError)
        }

        return agentClientError(problemDetailError)
    }

    private func parseProblemDetail(from responseBody: Data?) -> TangemProblemDetailError? {
        guard let responseBody else { return nil }
        return try? decoder.decode(TangemProblemDetailError.self, from: responseBody)
    }
}
