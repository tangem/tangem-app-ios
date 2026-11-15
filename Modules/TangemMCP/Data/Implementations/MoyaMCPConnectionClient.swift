//
//  MoyaMCPConnectionClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import enum Moya.MoyaError
import class Moya.MoyaProvider
import class Moya.Response
import struct TangemFoundation.UserWalletId
private import TangemNetworkUtils

struct MoyaMCPConnectionClient: MCPConnectionClient {
    private let provider: MoyaProvider<MCPDeviceVerificationTarget>
    private let baseURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        provider: MoyaProvider<MCPDeviceVerificationTarget>,
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
        let queryParameters = MCPDeviceVerificationDTO.Get.Request.QueryParameters(userCode: userCode)
        let target = MCPDeviceVerificationTarget.get(queryParameters: queryParameters, baseURL: baseURL)

        let response: Moya.Response
        do {
            response = try await provider.request(target)
        } catch {
            throw wrapped(moyaError: error, into: MCPConnectionClientError.fetchFailed)
        }

        do {
            let fetchResponse = try decoder.decode(MCPDeviceVerificationDTO.Get.Response.self, from: response.data)
            return MCPConnectionRequestMapper.mapToDomainRequest(fetchResponse)
        } catch {
            throw MCPConnectionClientError.fetchFailed(underlying: error)
        }
    }

    func accept(
        request: MCPConnectionRequest,
        userWalletID: UserWalletId
    ) async throws(MCPConnectionClientError) {
        let requestBody = MCPConnectionRequestMapper.mapDeviceVerificationPostBody(
            fromDomain: request,
            userWalletID: userWalletID
        )

        let target: MCPDeviceVerificationTarget
        do {
            target = try MCPDeviceVerificationTarget.post(
                accept: requestBody,
                queryParameters: MCPConnectionRequestMapper.mapDeviceVerificationPostQueryParameters(fromDomain: request),
                baseURL: baseURL,
                encoder: encoder
            )
        } catch {
            assertionFailure("Failed to construct MCPDeviceVerificationTarget. Post request body corrupted. Developer mistake.")
            throw MCPConnectionClientError.acceptFailed(underlying: error)
        }

        do {
            _ = try await provider.request(target)
        } catch {
            guard let problemDetailError = parseProblemDetail(from: error.response?.data) else {
                throw MCPConnectionClientError.acceptFailed(underlying: error)
            }

            if problemDetailError == .sessionRequestNotFound {
                throw MCPConnectionClientError.connectionRequestNotFound
            }

            throw MCPConnectionClientError.acceptFailed(underlying: problemDetailError)
        }
    }

    func reject(request: MCPConnectionRequest) async throws(MCPConnectionClientError) {
        let queryParameters = MCPConnectionRequestMapper.mapDeviceVerificationDeleteQueryParameters(fromDomain: request)
        let target = MCPDeviceVerificationTarget.delete(queryParameters: queryParameters, baseURL: baseURL)

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
