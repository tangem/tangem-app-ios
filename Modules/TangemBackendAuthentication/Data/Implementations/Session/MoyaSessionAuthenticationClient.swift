//
//  MoyaSessionAuthenticationClient.swift
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

struct MoyaSessionAuthenticationClient: SessionAuthenticationClient {
    private let dPoPProofGenerator: DPoPProofGenerator
    private let provider: MoyaProvider<BackendAuthenticationTarget>
    private let baseURL: URL
    private let decoder: JSONDecoder

    init(
        dPoPProofGenerator: DPoPProofGenerator,
        provider: MoyaProvider<BackendAuthenticationTarget>,
        baseURL: URL,
        decoder: JSONDecoder
    ) {
        self.dPoPProofGenerator = dPoPProofGenerator
        self.provider = provider
        self.baseURL = baseURL
        self.decoder = decoder
    }

    func requestCipheredNonce(devicePublicKey: DevicePublicKey) async throws(SessionAuthenticationClientError) -> String {
        let requestBody = NonceDTO.Request(devicePublicKey: devicePublicKey.derRepresentation.base64EncodedString())
        let target = BackendAuthenticationTarget(authenticationNonce: requestBody, baseURL: baseURL)

        let response: Moya.Response
        do {
            response = try await provider.request(target)
        } catch {
            throw error.isTimeout
                ? SessionAuthenticationClientError.requestNonceTimeout
                : wrapped(moyaError: error, into: SessionAuthenticationClientError.requestNonceFailed)
        }

        do {
            let nonceResponse = try decoder.decode(NonceDTO.Response.self, from: response.data)
            return nonceResponse.cipheredNonce
        } catch {
            throw SessionAuthenticationClientError.requestNonceFailed(underlying: error)
        }
    }

    func authenticate(
        devicePublicKey: DevicePublicKey,
        decryptedNonce: String,
        metadata: DeviceMetadata,
        signature: DeviceSignature,
        attestationToken: Data?
    ) async throws(SessionAuthenticationClientError) -> SessionTokens {
        let requestBody = AuthenticateDTO.Request(
            payload: AuthenticateDTO.Request.Payload(
                devicePublicKey: devicePublicKey.derRepresentation.base64EncodedString(),
                nonce: decryptedNonce,
                attestationToken: attestationToken?.base64EncodedString(),
                metadata: DeviceMetadataMapper.mapToDTO(metadata)
            ),
            signature: signature.derRepresentation.base64EncodedString()
        )
        let target = BackendAuthenticationTarget(authenticate: requestBody, baseURL: baseURL)

        let response: Moya.Response

        do {
            response = try await provider.request(target)
        } catch {
            switch error.response?.statusCode {
            case 401, 403:
                throw SessionAuthenticationClientError.authenticationRejected

            default:
                guard let problemDetailsError = parseProblemDetail(from: error.response?.data) else {
                    throw SessionAuthenticationClientError.authenticateFailed(underlying: error)
                }

                if problemDetailsError == .deviceNotFound {
                    throw SessionAuthenticationClientError.deviceRegistrationMissing
                }

                throw SessionAuthenticationClientError.authenticateFailed(underlying: problemDetailsError)
            }
        }

        do {
            let tokensResponse = try decoder.decode(TokensDTO.Response.self, from: response.data)
            return SessionTokensMapper.mapToDomain(tokensResponse)
        } catch {
            throw SessionAuthenticationClientError.authenticateFailed(underlying: error)
        }
    }

    func refresh(refreshToken: String, accessToken: String) async throws(SessionAuthenticationClientError) -> SessionTokens {
        let dPoPProof: DPoPProof
        do {
            dPoPProof = try await dPoPProofGenerator.generate(
                htm: BackendAuthenticationTarget.Refresh.htm,
                htu: BackendAuthenticationTarget.Refresh.htu(baseURL),
                accessToken: accessToken
            )
        } catch {
            throw SessionAuthenticationClientError.refreshFailed(underlying: error)
        }

        let requestBody = RefreshDTO.Request(refreshToken: refreshToken)
        let target = BackendAuthenticationTarget(
            authenticationRefresh: requestBody,
            baseURL: baseURL,
            dPoPProof: dPoPProof.value,
            accessToken: accessToken
        )

        let response: Moya.Response
        do {
            response = try await provider.request(target)
        } catch {
            throw wrapped(moyaError: error, into: SessionAuthenticationClientError.refreshFailed)
        }

        do {
            let tokensResponse = try decoder.decode(TokensDTO.Response.self, from: response.data)
            return SessionTokensMapper.mapToDomain(tokensResponse)
        } catch {
            throw SessionAuthenticationClientError.refreshFailed(underlying: error)
        }
    }
}

// MARK: - TangemProblemDetailError parsing

extension MoyaSessionAuthenticationClient {
    private func wrapped(
        moyaError: MoyaError,
        into clientError: (any Error) -> SessionAuthenticationClientError
    ) -> SessionAuthenticationClientError {
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
