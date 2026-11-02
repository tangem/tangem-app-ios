//
//  MoyaMCPSessionClient.swift
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

struct MoyaMCPSessionClient: MCPSessionClient {
    private let provider: MoyaProvider<MCPSessionsTarget>
    private let baseURL: URL
    private let decoder: JSONDecoder

    init(
        provider: MoyaProvider<MCPSessionsTarget>,
        baseURL: URL,
        decoder: JSONDecoder
    ) {
        self.provider = provider
        self.baseURL = baseURL
        self.decoder = decoder
    }

    func fetchAll() async throws(MCPSessionClientError) -> [MCPSession] {
        let target = MCPSessionsTarget.get(baseURL: baseURL)

        let response: Moya.Response
        do {
            response = try await provider.request(target)
        } catch {
            throw wrapped(moyaError: error, into: MCPSessionClientError.fetchFailed)
        }

        do {
            let responseDTO = try decoder.decode(MCPSessionsDTO.Get.Response.self, from: response.data)
            return try MCPSessionMapper.mapToDomain(responseDTO)
        } catch {
            throw MCPSessionClientError.fetchFailed(underlying: error)
        }
    }

    func revoke(sessionID: MCPSession.ID) async throws(MCPSessionClientError) {
        let target = MCPSessionsTarget.delete(sessionID: sessionID, baseURL: baseURL)

        do {
            _ = try await provider.request(target)
        } catch {
            switch error.response?.statusCode {
            case 404:
                throw MCPSessionClientError.sessionNotFound

            default:
                throw wrapped(moyaError: error, into: MCPSessionClientError.revokeFailed)
            }
        }
    }

    func revokeAll(userWalletID: UserWalletId) async throws(MCPSessionClientError) {
        let target = MCPSessionsTarget.delete(
            queryParameters: MCPSessionMapper.mapToDeleteQueryParameters(userWalletID),
            baseURL: baseURL
        )

        do {
            _ = try await provider.request(target)
        } catch {
            throw wrapped(moyaError: error, into: MCPSessionClientError.revokeAllFailed)
        }
    }
}

// MARK: - TangemProblemDetailError parsing

extension MoyaMCPSessionClient {
    private func wrapped(
        moyaError: MoyaError,
        into sessionClientError: (any Error) -> MCPSessionClientError
    ) -> MCPSessionClientError {
        guard let problemDetailError = parseProblemDetail(from: moyaError.response?.data) else {
            return sessionClientError(moyaError)
        }

        return sessionClientError(problemDetailError)
    }

    private func parseProblemDetail(from responseBody: Data?) -> TangemProblemDetailError? {
        guard let responseBody else { return nil }
        return try? decoder.decode(TangemProblemDetailError.self, from: responseBody)
    }
}
