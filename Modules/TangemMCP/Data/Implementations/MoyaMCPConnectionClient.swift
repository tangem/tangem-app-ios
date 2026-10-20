//
//  MoyaMCPConnectionClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import struct TangemFoundation.UserWalletId
private import TangemNetworkUtils

struct MoyaMCPConnectionClient: MCPConnectionClient {
    private let provider: MoyaProvider<MCPConnectionTarget>
    private let baseURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        provider: MoyaProvider<MCPConnectionTarget>,
        baseURL: URL,
        encoder: JSONEncoder,
        decoder: JSONDecoder
    ) {
        self.provider = provider
        self.baseURL = baseURL
        self.encoder = encoder
        self.decoder = decoder
    }

    func fetch(userCode: String) async throws(MCPConnectionClientError) -> MCPConnectionRequest {
        let queryParameters = FetchMCPConnectionRequestDTO.Request.QueryParameters(userCode: userCode)
        let target = MCPConnectionTarget.get(queryParameters: queryParameters, baseURL: baseURL)

        let response: Moya.Response
        do {
            response = try await provider.request(target)
        } catch {
            throw wrapped(moyaError: error, into: MCPConnectionClientError.fetchFailed)
        }

        do {
            let fetchResponse = try decoder.decode(FetchMCPConnectionRequestDTO.Response.self, from: response.data)
            return MCPConnectionRequestMapper.mapToDomainRequest(fetchResponse)
        } catch {
            throw MCPConnectionClientError.fetchFailed(underlying: error)
        }
    }

    func accept(
        request: MCPConnectionRequest,
        userWalletID: UserWalletId
    ) async throws(MCPConnectionClientError) {
        let requestBody = MCPConnectionRequestMapper.mapDecisionRequestBody(
            fromDomain: request,
            userWalletID: userWalletID
        )

        let target: MCPConnectionTarget
        do {
            target = try MCPConnectionTarget.post(
                accept: requestBody,
                queryParameters: MCPConnectionRequestMapper.mapDecisionRequestQueryParameters(fromDomain: request),
                baseURL: baseURL,
                encoder: encoder
            )
        } catch {
            assertionFailure("Failed to construct MCPConnectionTarget. Request body corrupted. Developer mistake.")
            throw MCPConnectionClientError.acceptFailed(underlying: error)
        }

        let response: Moya.Response
        do {
            response = try await provider.request(target)
        } catch {
            guard let problemDetailError = parseProblemDetail(from: error.response?.data) else {
                throw MCPConnectionClientError.acceptFailed(underlying: error)
            }

            if problemDetailError == .sessionRequestNotFound {
                throw MCPConnectionClientError.connectionRequestNotFound
            }

            throw MCPConnectionClientError.acceptFailed(underlying: problemDetailError)
        }

        do {
            _ = try decoder.decode(MCPConnectionDecisionDTO.Response.self, from: response.data)
        } catch {
            throw MCPConnectionClientError.acceptFailed(underlying: error)
        }
    }

    func reject(request: MCPConnectionRequest) async throws(MCPConnectionClientError) {
        let queryParameters = MCPConnectionRequestMapper.mapDecisionRequestQueryParameters(fromDomain: request)
        let target = MCPConnectionTarget.delete(queryParameters: queryParameters, baseURL: baseURL)

        do {
            _ = try await provider.request(target)
        } catch {
            guard let problemDetailError = parseProblemDetail(from: error.response?.data) else {
                throw MCPConnectionClientError.rejectFailed(underlying: error)
            }

            if problemDetailError == .sessionRequestNotFound {
                throw MCPConnectionClientError.connectionRequestNotFound
            }

            throw MCPConnectionClientError.rejectFailed(underlying: problemDetailError)
        }
    }
}

// MARK: - TangemProblemDetailError parsing

extension MoyaMCPConnectionClient {
    private func wrapped(
        moyaError: MoyaError,
        into connectionClientError: (any Error) -> MCPConnectionClientError
    ) -> MCPConnectionClientError {
        guard let problemDetailError = parseProblemDetail(from: moyaError.response?.data) else {
            return connectionClientError(moyaError)
        }

        return connectionClientError(problemDetailError)
    }

    private func parseProblemDetail(from responseBody: Data?) -> TangemProblemDetailError? {
        guard let responseBody else { return nil }
        return try? decoder.decode(TangemProblemDetailError.self, from: responseBody)
    }
}
