//
//  MoyaUserWalletRecoveryClient.swift
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

struct MoyaUserWalletRecoveryClient: UserWalletRecoveryClient {
    private let provider: MoyaProvider<BackendAuthenticationTarget>
    private let baseURL: URL
    private let decoder: JSONDecoder

    init(provider: MoyaProvider<BackendAuthenticationTarget>, baseURL: URL, decoder: JSONDecoder) {
        self.provider = provider
        self.baseURL = baseURL
        self.decoder = decoder
    }

    func requestCipheredNonce(devicePublicKey: DevicePublicKey) async throws(UserWalletRecoveryClientError) -> String {
        let requestBody = NonceDTO.Request(devicePublicKey: devicePublicKey.derRepresentation.base64EncodedString())
        let target = BackendAuthenticationTarget(recoverNonce: requestBody, baseURL: baseURL)

        let response: Moya.Response
        do {
            response = try await provider.request(target)
        } catch {
            throw wrapped(moyaError: error, into: UserWalletRecoveryClientError.requestNonceFailed)
        }

        do {
            let nonceResponse = try decoder.decode(NonceDTO.Response.self, from: response.data)
            return nonceResponse.cipheredNonce
        } catch {
            throw UserWalletRecoveryClientError.requestNonceFailed(underlying: error)
        }
    }
}

// MARK: - TangemProblemDetailError parsing

extension MoyaUserWalletRecoveryClient {
    private func wrapped(
        moyaError: MoyaError,
        into clientError: (any Error) -> UserWalletRecoveryClientError
    ) -> UserWalletRecoveryClientError {
        guard let problemDetailError = parseProblemDetail(from: moyaError.response?.data) else {
            return clientError(moyaError)
        }

        return clientError(problemDetailError)
    }

    private func parseProblemDetail(from responseBody: Data?) -> TangemProblemDetailError? {
        guard let responseBody else { return nil }
        return try? decoder.decode(TangemProblemDetailError.self, from: responseBody)
    }
}
