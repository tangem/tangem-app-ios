//
//  MoyaMCPSendIntentClient.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import class Alamofire.Interceptor
import enum TangemBackendAuthentication.BackendAuthenticationAssembly
import Moya
import TangemFoundation
import TangemNetworkUtils

struct MoyaMCPSendIntentClient {
    private let provider: MoyaProvider<MCPTransactionIntentTarget>
    private let baseURL: URL
    private let decoder = JSONDecoder()

    init(
        provider: MoyaProvider<MCPTransactionIntentTarget> = TangemProvider<MCPTransactionIntentTarget>(
            configuration: .ephemeralConfiguration,
            requestInterceptor: Alamofire.Interceptor(
                adapter: BackendAuthenticationAssembly.requestAdapter,
                retrier: BackendAuthenticationAssembly.requestRetrier
            )
        ),
        baseURL: URL = AppEnvironment.current.backendAuthenticationBaseUrl
    ) {
        self.provider = provider
        self.baseURL = baseURL
    }
}

// MARK: - Internal methods

extension MoyaMCPSendIntentClient {
    func fetch(intentId: String) async throws(SendMCPIntentError) -> SendMCPIntent {
        let target = MCPTransactionIntentTarget.get(intentId: try validated(intentId: intentId), baseURL: baseURL)

        let response: Moya.Response
        do {
            response = try await provider.request(target)
        } catch {
            throw sendIntentError(from: error)
        }

        let intent: FetchMCPSendIntentDTO.Response
        do {
            intent = try decoder.decode(FetchMCPSendIntentDTO.Response.self, from: response.data)
        } catch {
            throw .requestFailed(underlying: error)
        }

        return try SendMCPIntentMapper.mapToDomainIntent(intent)
    }

    func reportTransaction(sendIntentID: SendMCPIntent.ID, transactionHash: String) async throws(SendMCPIntentError) {
        let target = MCPTransactionIntentTarget.reportTransaction(
            intentId: try validated(intentId: sendIntentID),
            requestBody: ReportMCPSendIntentTransactionDTO.Request(txHash: transactionHash),
            baseURL: baseURL
        )

        do {
            _ = try await provider.request(target)
        } catch {
            throw sendIntentError(from: error)
        }
    }
}

// MARK: - Private

private extension MoyaMCPSendIntentClient {
    func validated(intentId: String) throws(SendMCPIntentError) -> String {
        guard UUID(uuidString: intentId) != nil else {
            throw .invalidIntentId(intentId)
        }

        return intentId
    }

    func sendIntentError(from error: MoyaError) -> SendMCPIntentError {
        if error.isTimeout {
            return .timeout
        }

        if error.isNotConnectedToInternet {
            return .noInternetConnection
        }

        return .requestFailed(underlying: error)
    }
}
