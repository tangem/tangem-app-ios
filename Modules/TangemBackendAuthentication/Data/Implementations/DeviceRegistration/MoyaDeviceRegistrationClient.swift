//
//  MoyaDeviceRegistrationClient.swift
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

struct MoyaDeviceRegistrationClient: DeviceRegistrationClient {
    private let provider: MoyaProvider<BackendAuthenticationTarget>
    private let baseURL: URL
    private let decoder: JSONDecoder

    init(provider: MoyaProvider<BackendAuthenticationTarget>, baseURL: URL, decoder: JSONDecoder) {
        self.provider = provider
        self.baseURL = baseURL
        self.decoder = decoder
    }

    func requestCipheredNonce(devicePublicKey: DevicePublicKey) async throws(DeviceRegistrationClientError) -> String {
        let requestBody = NonceDTO.Request(devicePublicKey: devicePublicKey.derRepresentation.base64EncodedString())
        let target = BackendAuthenticationTarget(deviceRegistrationNonce: requestBody, baseURL: baseURL)

        let response: Moya.Response
        do {
            response = try await provider.request(target)
        } catch {
            throw error.isTimeout
                ? DeviceRegistrationClientError.requestNonceTimeout
                : wrapped(moyaError: error, into: DeviceRegistrationClientError.requestNonceFailed)
        }

        do {
            let nonceResponse = try decoder.decode(NonceDTO.Response.self, from: response.data)
            return nonceResponse.cipheredNonce
        } catch {
            throw DeviceRegistrationClientError.requestNonceFailed(underlying: error)
        }
    }

    func register(request: DeviceRegistrationRequest) async throws(DeviceRegistrationClientError) -> SessionTokens {
        let requestBody = RegisterDeviceDTO.Request(
            payload: RegisterDeviceDTO.Request.Payload(
                devicePublicKey: request.devicePublicKey.derRepresentation.base64EncodedString(),
                nonce: request.decryptedNonce,
                attestationToken: request.appAttestationToken?.base64EncodedString(),
                metadata: DeviceMetadataMapper.mapToDTO(request.metadata)
            ),
            signature: request.signature.derRepresentation.base64EncodedString()
        )
        let target = BackendAuthenticationTarget(registerDevice: requestBody, baseURL: baseURL)

        let response: Moya.Response

        do {
            response = try await provider.request(target)
        } catch {
            guard let problemDetailError = parseProblemDetail(from: error.response?.data) else {
                throw DeviceRegistrationClientError.registerFailed(underlying: error)
            }

            if problemDetailError == .deviceAlreadyRegistered {
                throw DeviceRegistrationClientError.alreadyRegistered
            }

            throw DeviceRegistrationClientError.registerFailed(underlying: problemDetailError)
        }

        do {
            let tokensResponse = try decoder.decode(TokensDTO.Response.self, from: response.data)
            return SessionTokensMapper.mapToDomain(tokensResponse)
        } catch {
            throw DeviceRegistrationClientError.registerFailed(underlying: error)
        }
    }
}

// MARK: - TangemProblemDetailError parsing

extension MoyaDeviceRegistrationClient {
    private func wrapped(
        moyaError: MoyaError,
        into clientError: (any Error) -> DeviceRegistrationClientError
    ) -> DeviceRegistrationClientError {
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
