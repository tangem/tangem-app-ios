//
//  MoyaUserWalletRegistrationClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import enum Moya.MoyaError
import class Moya.MoyaProvider
import class Moya.Response
import TangemFoundation
private import TangemNetworkUtils

struct MoyaUserWalletRegistrationClient: UserWalletRegistrationClient {
    private let provider: MoyaProvider<UserWalletTarget>
    private let nonceProvider: MoyaProvider<BackendAuthenticationTarget>
    private let baseURL: URL
    private let decoder: JSONDecoder

    init(
        provider: MoyaProvider<UserWalletTarget>,
        nonceProvider: MoyaProvider<BackendAuthenticationTarget>,
        baseURL: URL,
        decoder: JSONDecoder
    ) {
        self.provider = provider
        self.nonceProvider = nonceProvider
        self.baseURL = baseURL
        self.decoder = decoder
    }

    func requestCipheredNonce(devicePublicKey: DevicePublicKey) async throws(UserWalletRegistrationClientError) -> String {
        let requestBody = NonceDTO.Request(devicePublicKey: devicePublicKey.derRepresentation.base64EncodedString())
        let target = BackendAuthenticationTarget(walletRegistrationNonce: requestBody, baseURL: baseURL)

        let response: Moya.Response
        do {
            response = try await nonceProvider.request(target)
        } catch {
            throw error.isTimeout
                ? UserWalletRegistrationClientError.requestNonceTimeout
                : wrapped(moyaError: error, into: UserWalletRegistrationClientError.requestNonceFailed)
        }

        do {
            let nonceResponse = try decoder.decode(NonceDTO.Response.self, from: response.data)
            return nonceResponse.cipheredNonce
        } catch {
            throw UserWalletRegistrationClientError.requestNonceFailed(underlying: error)
        }
    }

    func register(request: UserWalletRegistrationRequest) async throws(UserWalletRegistrationClientError) -> SessionTokens {
        let requestBody = UserWalletRegistrationRequestMapper.map(fromDomain: request)
        let target = UserWalletTarget(registerWallet: requestBody, baseURL: baseURL)

        let response: Moya.Response

        do {
            response = try await provider.request(target)
        } catch {
            guard let problemDetailsError = parseProblemDetail(from: error.response?.data) else {
                throw UserWalletRegistrationClientError.registerFailed(underlying: error)
            }

            if problemDetailsError == .walletAlreadyRegistered {
                throw UserWalletRegistrationClientError.alreadyRegistered
            }

            throw UserWalletRegistrationClientError.registerFailed(underlying: problemDetailsError)
        }

        do {
            let tokensResponse = try decoder.decode(TokensDTO.Response.self, from: response.data)
            return SessionTokensMapper.mapToDomain(tokensResponse)
        } catch {
            throw UserWalletRegistrationClientError.registerFailed(underlying: error)
        }
    }

    func unregister(
        id: UserWalletId,
        shouldEraseSocialLoginData: Bool
    ) async throws(UserWalletRegistrationClientError) -> SessionTokens {
        let requestBody = UnregisterWalletDTO.Request(
            walletId: id.value.base64EncodedString(),
            eraseData: shouldEraseSocialLoginData
        )
        let target = UserWalletTarget(unregisterWallet: requestBody, baseURL: baseURL)

        let response: Moya.Response

        do {
            response = try await provider.request(target)
        } catch {
            guard let problemDetailsError = parseProblemDetail(from: error.response?.data) else {
                throw UserWalletRegistrationClientError.unregisterFailed(underlying: error)
            }

            if problemDetailsError == .walletNotRegistered {
                throw UserWalletRegistrationClientError.wasNotRegistered
            }

            throw UserWalletRegistrationClientError.unregisterFailed(underlying: problemDetailsError)
        }

        do {
            let tokensResponse = try decoder.decode(TokensDTO.Response.self, from: response.data)
            return SessionTokensMapper.mapToDomain(tokensResponse)
        } catch {
            throw UserWalletRegistrationClientError.unregisterFailed(underlying: error)
        }
    }
}

// MARK: - TangemProblemDetailError parsing

extension MoyaUserWalletRegistrationClient {
    private func wrapped(
        moyaError: MoyaError,
        into clientError: (any Error) -> UserWalletRegistrationClientError
    ) -> UserWalletRegistrationClientError {
        guard let problemDetailsError = parseProblemDetail(from: moyaError.response?.data) else {
            return clientError(moyaError)
        }

        return clientError(problemDetailsError)
    }

    private func parseProblemDetail(from responseBody: Data?) -> TangemProblemDetailError? {
        guard let responseBody else { return nil }
        return try? decoder.decode(TangemProblemDetailError.self, from: responseBody)
    }
}
