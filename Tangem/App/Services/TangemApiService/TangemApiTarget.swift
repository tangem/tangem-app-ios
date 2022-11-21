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

    var baseURL: URL {
        URL(string: AppEnvironment.current.apiBaseUrl)!
    }

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
        case .loadReferralProgramInfo(let userWalletId):
            return "/referral/\(userWalletId)"
        case .participateInReferralProgram:
            return "/referral"
        }
    }

    var method: Moya.Method {
        switch type {
        case .rates, .currencies, .coins, .geo, .getUserWalletTokens, .loadReferralProgramInfo:
            return .get
        case .saveUserWalletTokens:
            return .put
        case .participateInReferralProgram:
            return .post
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
        case let .saveUserWalletTokens(_, list):
            return .requestJSONEncodable(list)
        case .loadReferralProgramInfo:
            return .requestPlain
        case .participateInReferralProgram(let requestData):
            return .requestURLEncodable(requestData)
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
        case saveUserWalletTokens(key: String, list: UserTokenList)
        case loadReferralProgramInfo(userWalletId: String)
        case participateInReferralProgram(userInfo: ReferralParticipationRequestBody)
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

extension TangemApiTarget: CachePolicyProvider {
    var cachePolicy: URLRequest.CachePolicy {
        switch type {
        case .geo:
            return .reloadIgnoringLocalAndRemoteCacheData
        default:
            return .useProtocolCachePolicy
        }
    }
}
