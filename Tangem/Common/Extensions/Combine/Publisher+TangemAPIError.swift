//
//  Publisher+TangemAPIError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

extension Publisher where Failure == MoyaError {
    func mapTangemAPIError() -> Publishers.MapError<Self, TangemAPIError> {
        mapError { error in
            guard let body = error.response?.data else {
                return TangemAPIError(code: .unknown, message: error.localizedDescription)
            }

            let decoder = JSONDecoder()

            if let error = try? mapBaseAPIError(from: body, using: decoder) {
                return error
            }

            if let error = try? mapInputAPIError(from: body, using: decoder) {
                return error
            }

            return TangemAPIError(code: .decode)
        }
    }

    private func mapBaseAPIError(from body: Data, using decoder: JSONDecoder) throws -> TangemAPIError {
        return try decoder
            .decode(TangemBaseAPIError.self, from: body)
            .error
    }

    private func mapInputAPIError(from body: Data, using decoder: JSONDecoder) throws -> TangemAPIError {
        let error = try decoder.decode(TangemInputAPIError.self, from: body)

        guard let code = TangemAPIError.ErrorCode(rawValue: error.statusCode) else {
            throw TangemAPIError(code: .decode)
        }

        return TangemAPIError(code: code, message: error.message.first ?? error.error)
    }
}
