//
//  Error+UserWalletNotAuthorized.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

extension Error {
    var isUserWalletNotAuthorized: Bool {
        if let problemDetail = self as? TangemProblemDetailError {
            return problemDetail.httpStatusCode == UserWalletNotAuthorizedBody.statusCode
                && problemDetail.code == UserWalletNotAuthorizedBody.errorCode
        }

        guard
            let response = (self as? MoyaError)?.response,
            response.statusCode == UserWalletNotAuthorizedBody.statusCode,
            let body = try? JSONDecoder().decode(UserWalletNotAuthorizedBody.self, from: response.data)
        else {
            return false
        }

        return body.errorCode == UserWalletNotAuthorizedBody.errorCode
    }
}

private struct UserWalletNotAuthorizedBody: Decodable {
    static let statusCode = 403
    static let errorCode = "WALLET_NOT_AUTHORIZED"

    let errorCode: String?

    private enum CodingKeys: String, CodingKey {
        case code
        case errorCode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        errorCode = try container.decodeIfPresent(String.self, forKey: .errorCode)
            ?? container.decodeIfPresent(String.self, forKey: .code)
    }
}
