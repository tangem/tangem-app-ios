//
//  Moya+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

extension Response {
    func filterResponseThrowingTangemAPIError(allowRedirectCodes: Bool) throws -> Moya.Response {
        let filteredResponse: Response

        do {
            filteredResponse = try allowRedirectCodes
                ? filterSuccessfulStatusAndRedirectCodes()
                : filterSuccessfulStatusCodes()
        } catch {
            // Trying to map `TangemAPIError` from the response with a status code different than 2XX/3XX
            throw TangemAPIErrorMapper.map(response: self) ?? error
        }

        // Trying to map `TangemAPIError` from the response with a 2XX/3XX status code
        if let tangemAPIError = TangemAPIErrorMapper.map(response: filteredResponse) {
            throw tangemAPIError
        }

        return filteredResponse
    }

    func mapAPIResponseThrowingTangemAPIError<D: Decodable>(allowRedirectCodes: Bool, decoder: JSONDecoder = .init()) throws -> D {
        let filteredResponse = try filterResponseThrowingTangemAPIError(allowRedirectCodes: allowRedirectCodes)

        return try filteredResponse.map(D.self, using: decoder)
    }
}
