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
                : DeviceRegistrationClientError.requestNonceFailed(underlying: error)
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
            switch error.response?.statusCode {
            case 409:
                throw DeviceRegistrationClientError.alreadyRegistered
            default:
                throw DeviceRegistrationClientError.registerFailed(underlying: error)
            }
        }

        do {
            let tokensResponse = try decoder.decode(TokensDTO.Response.self, from: response.data)
            return SessionTokensMapper.mapToDomain(tokensResponse)
        } catch {
            throw DeviceRegistrationClientError.registerFailed(underlying: error)
        }
    }
}
