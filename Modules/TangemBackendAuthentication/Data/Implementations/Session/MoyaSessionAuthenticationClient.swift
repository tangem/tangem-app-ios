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
                : SessionAuthenticationClientError.requestNonceFailed(underlying: error)
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

            case 404 where isDeviceNotFound(error.response?.data):
                throw SessionAuthenticationClientError.deviceRegistrationMissing

            default:
                throw SessionAuthenticationClientError.authenticateFailed(underlying: error)
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
        do {
            let dPoPProof = try await dPoPProofGenerator.generate(
                htm: BackendAuthenticationTarget.Refresh.htm,
                htu: BackendAuthenticationTarget.Refresh.htu(baseURL),
                accessToken: accessToken
            )

            let requestBody = RefreshDTO.Request(refreshToken: refreshToken)
            let target = BackendAuthenticationTarget(
                authenticationRefresh: requestBody,
                baseURL: baseURL,
                dPoPProof: dPoPProof.value,
                accessToken: accessToken
            )

            let response = try await provider.request(target)
            let tokensResponse = try decoder.decode(TokensDTO.Response.self, from: response.data)

            return SessionTokensMapper.mapToDomain(tokensResponse)
        } catch {
            throw SessionAuthenticationClientError.refreshFailed(underlying: error)
        }
    }

    private func isDeviceNotFound(_ responseBody: Data?) -> Bool {
        guard
            let responseBody,
            let problemDetailDTO = try? decoder.decode(ProblemDetailDTO.Response.self, from: responseBody)
        else {
            return false
        }

        return problemDetailDTO == ProblemDetailDTO.Response.deviceNotFound
    }
}
