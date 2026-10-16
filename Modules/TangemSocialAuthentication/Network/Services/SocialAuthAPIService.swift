//
//  SocialAuthAPIService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils

protocol SocialAuthAPIService {
    func recoverWallet(request: RecoverWalletDTO.Request) async throws(SocialAuthAPIError) -> RecoverWalletDTO.Response
    func recoveryPublicKey() async throws(SocialAuthAPIError) -> RecoveryPublicKeyDTO.Response
}

// MARK: - CommonSocialAuthAPIService

final class CommonSocialAuthAPIService {
    private let provider: TangemProvider<SocialAuthTarget>
    private let baseURL: URL

    private let decoder = JSONDecoder()

    init(provider: TangemProvider<SocialAuthTarget>, baseURL: URL) {
        self.provider = provider
        self.baseURL = baseURL
    }
}

// MARK: - SocialAuthAPIService

extension CommonSocialAuthAPIService: SocialAuthAPIService {
    func recoverWallet(request: RecoverWalletDTO.Request) async throws(SocialAuthAPIError) -> RecoverWalletDTO.Response {
        try await self.request(.recoverWallet(request: request))
    }

    func recoveryPublicKey() async throws(SocialAuthAPIError) -> RecoveryPublicKeyDTO.Response {
        try await request(.recoveryPublicKey)
    }
}

// MARK: - Private

private extension CommonSocialAuthAPIService {
    func request<T: Decodable>(_ endpoint: SocialAuthTarget.Endpoint) async throws(SocialAuthAPIError) -> T {
        let response = try await perform(endpoint)

        do {
            return try decoder.decode(T.self, from: response.data)
        } catch {
            throw SocialAuthAPIError.decoding(underlying: error)
        }
    }

    @discardableResult
    func perform(_ endpoint: SocialAuthTarget.Endpoint) async throws(SocialAuthAPIError) -> Response {
        let target = SocialAuthTarget(baseURL: baseURL, endpoint: endpoint)

        do {
            let response = try await provider.requestPublisher(target).async()
            return try response.filterSuccessfulStatusAndRedirectCodes()
        } catch let error as MoyaError {
            throw Self.mapMoyaError(error, decoder: decoder)
        } catch {
            throw SocialAuthAPIError.connection(underlying: error)
        }
    }

    static func mapMoyaError(_ error: MoyaError, decoder: JSONDecoder) -> SocialAuthAPIError {
        guard let response = error.response else {
            return .connection(underlying: error.underlyingError ?? error)
        }

        let problemDetail = try? decoder.decode(SocialAuthProblemDetail.self, from: response.data)
        return .http(statusCode: response.statusCode, problemDetail: problemDetail)
    }
}
