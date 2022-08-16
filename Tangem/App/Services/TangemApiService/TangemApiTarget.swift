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

    // https://api.tangem-tech.com/v1/user-wallets/:key/
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
        case let .getUserWalletTokens(key), let .saveUserWalletTokens(key, _):
            return "/user-tokens/\(key)"
        }
    }

    var method: Moya.Method {
        switch type {
        case .rates, .currencies, .coins, .geo, .getUserWalletTokens:
            return .get
        case .saveUserWalletTokens:
            return .put
        }
    }

    var task: Task {
        switch type {
        case .rates(let coinIds, let currencyId):
            return .requestParameters(parameters: ["coinIds": coinIds.joined(separator: ","),
                                                   "currencyId": currencyId.lowercased()],
                                      encoding: URLEncoding.default)
        case let .coins(pageModel):
            return .requestURLEncodable(pageModel)
        case .currencies, .geo, .getUserWalletTokens:
            return .requestPlain
        case let .saveUserWalletTokens(_, tokenList):
            return .requestJSONEncodable(tokenList)
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
        case getUserWalletTokens(key: String)
        case saveUserWalletTokens(key: String, tokens: UserTokenList)
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
