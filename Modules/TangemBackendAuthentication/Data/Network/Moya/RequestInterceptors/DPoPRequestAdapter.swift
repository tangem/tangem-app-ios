//
//  DPoPRequestAdapter.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import protocol Alamofire.RequestAdapter
import class Alamofire.Session
import struct TangemLogger.Logger

/// Attaches `Authorization`/`DPoP` headers to every request sent through a provider carrying this adapter.
/// Resolves a still-valid cached access token when one exists, or renews the session otherwise via ``RenewSessionTokensUseCase``.
struct DPoPRequestAdapter: RequestAdapter {
    private let renewSessionTokensUseCase: RenewSessionTokensUseCase
    private let sessionTokensRepository: any SessionTokensRepository
    private let dPoPProofGenerator: DPoPProofGenerator
    private let dateProvider: @Sendable () -> Date
    private let logger: Logger

    init(
        renewSessionTokensUseCase: RenewSessionTokensUseCase,
        sessionTokensRepository: some SessionTokensRepository,
        dPoPProofGenerator: DPoPProofGenerator,
        dateProvider: @escaping @Sendable @autoclosure () -> Date = Date.now,
        logger: Logger
    ) {
        self.renewSessionTokensUseCase = renewSessionTokensUseCase
        self.sessionTokensRepository = sessionTokensRepository
        self.dPoPProofGenerator = dPoPProofGenerator
        self.dateProvider = dateProvider
        self.logger = logger
    }

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping @Sendable (Result<URLRequest, any Error>) -> Void
    ) {
        Task {
            do {
                let accessToken = try await resolveValidAccessToken()

                guard let method = urlRequest.httpMethod, let url = urlRequest.url else {
                    completion(.success(urlRequest))
                    return
                }

                let dPoPProof = try await dPoPProofGenerator.generate(
                    htm: method,
                    htu: Self.htu(from: url),
                    accessToken: accessToken
                )

                var adaptedHeaders = urlRequest.allHTTPHeaderFields ?? [:]
                adaptedHeaders.merge(DPoPHeadersFactory.make(accessToken: accessToken, dPoPProof: dPoPProof.value)) { _, new in new }

                var adaptedRequest = urlRequest
                adaptedRequest.allHTTPHeaderFields = adaptedHeaders

                completion(.success(adaptedRequest))
            } catch {
                // Per backend guidance, a request missing its DPoP headers is treated the same as any
                // other unauthenticated request — sending it through lets RenewSessionTokensRequestRetrier
                // get its own independent shot at recovery once the real 401/403 comes back, rather than
                // us denying that chance by failing here on what might be a transient renewal failure.
                logger.error("Failed to attach DPoP headers, sending request unauthenticated", error: error)
                completion(.success(urlRequest))
            }
        }
    }

    private func resolveValidAccessToken() async throws -> String {
        guard
            let cachedAccessToken = try await sessionTokensRepository.retrieve()?.accessToken,
            dateProvider() < cachedAccessToken.expiresAt
        else {
            return try await renewSessionTokensUseCase().accessToken.jwt
        }

        return cachedAccessToken.jwt
    }

    /// RFC 9449 §4.2 `htu`: the request's URI, stripped of query and fragment.
    private static func htu(from url: URL) -> String {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil
        components?.fragment = nil
        return components?.url?.absoluteString ?? url.absoluteString
    }
}
