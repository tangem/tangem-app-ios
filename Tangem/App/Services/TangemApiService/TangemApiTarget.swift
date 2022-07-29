//
//  TangemApiTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Moya
import TangemSdk

struct TangemApiTarget: TargetType {
    let type: TargetType
    let authData: AuthData?

    var baseURL: URL { URL(string: "https://api.tangem-tech.com/v1")! }

    var path: String {
        switch type {
        case .rates:
            return "/rates"
        case .currencies:
            return "/currencies"
        case .coins:
            return "/coins"
        case .geo:
            return "/geo"
        }
    }

    var method: Moya.Method { .get }

    var task: Task {
        switch type {
        case .rates(let coinIds, let currencyId):
            return .requestParameters(parameters: ["coinIds": coinIds.joined(separator: ","),
                                                   "currencyId": currencyId.lowercased()],
                                      encoding: URLEncoding.default)
        case let .coins(pageModel):
            return .requestURLEncodable(pageModel)
        case .currencies, .geo:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        authData?.headers
    }
}

extension TangemApiTarget {
    enum TargetType {
        case rates(coinIds: [String], currencyId: String)
        case currencies
        case coins(_ requestModel: CoinsListRequestModel)
        case geo
    }

    struct AuthData {
        let cardId: String
        let cardPublicKey: Data

        var headers: [String: String] {
            [
                "card_id": cardId,
                "card_public_key": cardPublicKey.hexString,
            ]
        }
    }
}
