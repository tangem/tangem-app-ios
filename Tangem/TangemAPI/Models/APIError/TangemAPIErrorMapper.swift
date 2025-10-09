//
//  TangemAPIErrorMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum TangemAPIErrorMapper {
    static func map(response: Response) -> TangemAPIError? {
        let body = response.data
        let decoder = JSONDecoder()

        if let error = try? mapFromBaseAPIError(body, using: decoder) {
            return error
        }

        if let error = try? mapFromInputAPIError(body, using: decoder) {
            return error
        }

        if let error = mapFromStatusCode(response.statusCode) {
            return error
        }

        return nil
    }

    private static func mapFromBaseAPIError(_ body: Data, using decoder: JSONDecoder) throws -> TangemAPIError {
        let error = try decoder.decode(TangemBaseAPIError.self, from: body)

        return error.error
    }

    private static func mapFromInputAPIError(_ body: Data, using decoder: JSONDecoder) throws -> TangemAPIError {
        let error = try decoder.decode(TangemInputAPIError.self, from: body)

        return TangemAPIError(code: error.statusCode, message: error.message.first ?? error.error)
    }

    private static func mapFromStatusCode(_ statusCode: Int) -> TangemAPIError? {
        if let errorCode = TangemAPIError.ErrorCode(rawValue: statusCode) {
            return TangemAPIError(code: errorCode)
        }

        return nil
    }
}
