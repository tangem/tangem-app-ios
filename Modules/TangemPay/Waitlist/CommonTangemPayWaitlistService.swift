//
//  CommonTangemPayWaitlistService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class CommonTangemPayWaitlistService {
    private let apiService: TangemPayAPIService<TangemPayWaitlistAPITarget>
    private let apiType: VisaAPIType

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    init(
        apiType: VisaAPIType,
        apiService: TangemPayAPIService<TangemPayWaitlistAPITarget>
    ) {
        self.apiType = apiType
        self.apiService = apiService
    }
}

extension CommonTangemPayWaitlistService: TangemPayWaitlistService {
    func joinWaitlist(
        _ request: TangemPayJoinWaitlistRequest,
        idempotencyKey: String
    ) async throws(TangemPayWaitlistError) -> TangemPayJoinWaitlistResponse {
        do {
            return try await apiService.request(
                .init(
                    target: .joinWaitlist(request: request, idempotencyKey: idempotencyKey),
                    apiType: apiType,
                    encoder: encoder
                )
            )
        } catch {
            throw TangemPayWaitlistError(error)
        }
    }
}

// MARK: - Error mapping

private extension TangemPayWaitlistError {
    init(_ error: TangemPayAPIServiceError) {
        guard
            case .apiError(let apiError) = error,
            apiError.name == TangemPayAPIError.Name.waitlistInvalidEmail
        else {
            self = .failed(error)
            return
        }

        self = .invalidEmail
    }
}
