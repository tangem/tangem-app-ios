//
//  MoyaUserWalletRecoveryClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import class Moya.MoyaProvider

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
        do {
            let requestBody = NonceDTO.Request(devicePublicKey: devicePublicKey.derRepresentation.base64EncodedString())
            let target = BackendAuthenticationTarget(recoverNonce: requestBody, baseURL: baseURL)

            let response = try await provider.request(target)
            let nonceResponse = try decoder.decode(NonceDTO.Response.self, from: response.data)

            return nonceResponse.cipheredNonce
        } catch {
            throw UserWalletRecoveryClientError.requestNonceFailed(underlying: error)
        }
    }
}
