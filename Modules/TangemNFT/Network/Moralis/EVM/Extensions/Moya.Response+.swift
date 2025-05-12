//
//  Moya.Response+.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya

extension Response {
    func mapAPIResponse<T>(_ type: T.Type, using decoder: JSONDecoder) throws -> T where T: Decodable {
        let response: Response

        do {
            response = try filterSuccessfulStatusAndRedirectCodes()
        } catch {
            try handleUnsuccessfulStatusCodes(with: error, using: decoder)
        }

        return try response.map(T.self, using: decoder)
    }

    /// - Note: `Never` return type is used to silence the compiler, this method always throws an error.
    private func handleUnsuccessfulStatusCodes(with error: Error, using decoder: JSONDecoder) throws -> Never {
        guard let apiError = try? map(MoralisEVMNetworkResult.APIError.self, using: decoder) else {
            throw error
        }

        throw MoralisEVMNFTNetworkService.Error.apiError(message: apiError.message)
    }
}
