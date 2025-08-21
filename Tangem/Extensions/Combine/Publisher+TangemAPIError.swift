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
            guard let response = error.response else {
                return TangemAPIError(code: .unknown, message: error.localizedDescription)
            }
            let body = response.data

            let decoder = JSONDecoder()

            if let error = try? mapBaseAPIError(from: body, using: decoder) {
                return error
            }

            if let error = try? mapInputAPIError(from: body, using: decoder) {
                return error
            }

            if let error = mapStatusCodeToError(code: response.statusCode) {
                return error
            }

            return TangemAPIError(code: .decode)
        }
    }

    private func mapStatusCodeToError(code: Int) -> TangemAPIError? {
        switch code {
        case 400:
            return TangemAPIError(code: .badRequest)
        case 403:
            return TangemAPIError(code: .forbidden)
        case 404:
            return TangemAPIError(code: .notFound)
        case 409:
            return TangemAPIError(code: .conflict)
        case 422:
            return TangemAPIError(code: .unprocessableEntity)
        default:
            return nil
        }
    }

    private func mapBaseAPIError(from body: Data, using decoder: JSONDecoder) throws -> TangemAPIError {
        return try decoder
            .decode(TangemBaseAPIError.self, from: body)
            .error
    }

    private func mapInputAPIError(from body: Data, using decoder: JSONDecoder) throws -> TangemAPIError {
        let error = try decoder.decode(TangemInputAPIError.self, from: body)

        return TangemAPIError(code: error.statusCode, message: error.message.first ?? error.error)
    }
}
