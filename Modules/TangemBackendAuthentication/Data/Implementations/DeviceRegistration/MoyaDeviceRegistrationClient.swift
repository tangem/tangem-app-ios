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
import TangemFoundation

struct MoyaDeviceRegistrationClient: DeviceRegistrationClient {
    private let provider: MoyaProvider<BackendAuthenticationTarget>
    private let baseURL: URL
    private let decoder: JSONDecoder

    init(provider: MoyaProvider<BackendAuthenticationTarget>, baseURL: URL) {
        self.provider = provider
        self.baseURL = baseURL

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .customISO8601
    }

    func requestCipheredNonce(devicePublicKey: DevicePublicKey) async throws(DeviceRegistrationClientError) -> String {
        do {
            let requestBody = NonceDTO.Request(devicePublicKey: devicePublicKey.derRepresentation.base64EncodedString())
            let target = BackendAuthenticationTarget(deviceRegistrationNonce: requestBody, baseURL: baseURL)

            let response = try await provider.request(target)
            let nonceResponse = try decoder.decode(NonceDTO.Response.self, from: response.data)

            return nonceResponse.cipheredNonce
        } catch {
            throw DeviceRegistrationClientError.requestNonceFailed(underlying: error)
        }
    }

    func register(
        devicePublicKey: DevicePublicKey,
        decryptedNonce: String,
        metadata: DeviceMetadata,
        signature: DeviceSignature,
        attestationToken: Data?
    ) async throws(DeviceRegistrationClientError) -> SessionTokens {
        let requestBody = RegisterDeviceDTO.Request(
            payload: RegisterDeviceDTO.Request.Payload(
                devicePublicKey: devicePublicKey.derRepresentation.base64EncodedString(),
                nonce: decryptedNonce,
                attestationToken: attestationToken?.base64EncodedString(),
                metadata: DeviceMetadataMapper.mapToDTO(metadata)
            ),
            signature: signature.derRepresentation.base64EncodedString()
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
