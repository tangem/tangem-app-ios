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
                : UserWalletRegistrationClientError.requestNonceFailed(underlying: error)
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
            switch error.response?.statusCode {
            case 400 where isWalletAlreadyRegistered(error.response?.data):
                throw UserWalletRegistrationClientError.alreadyRegistered

            default:
                throw UserWalletRegistrationClientError.registerFailed(underlying: error)
            }
        }

        do {
            let tokensResponse = try decoder.decode(TokensDTO.Response.self, from: response.data)
            return SessionTokensMapper.mapToDomain(tokensResponse)
        } catch {
            throw UserWalletRegistrationClientError.registerFailed(underlying: error)
        }
    }

    func unregister(id: UserWalletId) async throws(UserWalletRegistrationClientError) -> SessionTokens {
        let requestBody = UnregisterWalletDTO.Request(walletId: id.value.base64EncodedString())
        let target = UserWalletTarget(unregisterWallet: requestBody, baseURL: baseURL)

        let response: Moya.Response

        do {
            response = try await provider.request(target)
        } catch {
            switch error.response?.statusCode {
            case 404 where isWalletNotRegistered(error.response?.data):
                throw UserWalletRegistrationClientError.wasNotRegistered

            default:
                throw UserWalletRegistrationClientError.unregisterFailed(underlying: error)
            }
        }

        do {
            let tokensResponse = try decoder.decode(TokensDTO.Response.self, from: response.data)
            return SessionTokensMapper.mapToDomain(tokensResponse)
        } catch {
            throw UserWalletRegistrationClientError.unregisterFailed(underlying: error)
        }
    }
}

// MARK: - ProblemDetail parsing

extension MoyaUserWalletRegistrationClient {
    private func isWalletAlreadyRegistered(_ responseBody: Data?) -> Bool {
        parseProblemDetail(from: responseBody) == ProblemDetailDTO.Response.walletAlreadyRegistered
    }

    private func isWalletNotRegistered(_ responseBody: Data?) -> Bool {
        parseProblemDetail(from: responseBody) == ProblemDetailDTO.Response.walletNotRegistered
    }

    private func parseProblemDetail(from responseBody: Data?) -> ProblemDetailDTO.Response? {
        guard let responseBody else { return nil }
        return try? decoder.decode(ProblemDetailDTO.Response.self, from: responseBody)
    }
}
