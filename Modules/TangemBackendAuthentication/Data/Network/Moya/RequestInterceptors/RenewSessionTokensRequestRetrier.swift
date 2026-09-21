//
//  RenewSessionTokensRequestRetrier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import Foundation
import Alamofire
import struct TangemLogger.Logger

/// Retries a request exactly once, after a fresh renewal, on 401 and never a second time on the same request.
/// A repeat failure right after a fresh token means the session is genuinely dead, not something another attempt would fix.
struct RenewSessionTokensRequestRetrier: RequestRetrier {
    private let renewSessionTokensUseCase: RenewSessionTokensUseCase
    private let logger: Logger

    init(renewSessionTokensUseCase: RenewSessionTokensUseCase, logger: Logger) {
        self.renewSessionTokensUseCase = renewSessionTokensUseCase
        self.logger = logger
    }

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: any Error,
        completion: @escaping @Sendable (RetryResult) -> Void
    ) {
        guard let statusCode = request.response?.statusCode, request.retryCount == 0 else {
            completion(.doNotRetry)
            return
        }

        switch statusCode {
        case 401:
            attemptSessionTokensRenewal(completion)

        case 403:
            completion(.doNotRetryWithError(error))

        default:
            completion(.doNotRetry)
        }
    }

    private func attemptSessionTokensRenewal(_ completion: @escaping @Sendable (RetryResult) -> Void) {
        Task {
            do {
                _ = try await renewSessionTokensUseCase()
                completion(.retry)
            } catch {
                logger.error(
                    "Failed to renew session tokens. Retry will not be performed. The request is treated as failed.",
                    error: error
                )
                completion(.doNotRetryWithError(error))
            }
        }
    }
}
