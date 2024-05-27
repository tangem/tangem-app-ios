//
//  StakekitTarget.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct StakekitTarget: Moya.TargetType {
    let apiKey: String
    let target: Target

    enum Target {
        case enabledYields
        case getYield(StakekitDTO.Yield.Info.Request)

        case enterAction(StakekitDTO.Actions.Enter.Request)
    }

    var baseURL: URL {
        URL(string: "https://api.stakek.it/v1/")!
    }

    var path: String {
        switch target {
        case .enabledYields:
            return "yields/enabled"
        case .getYield(let stakekitDTO):
            return "yields/\(stakekitDTO.integrationId)"
        case .enterAction:
            return "actions/enter"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getYield, .enabledYields:
            return .get
        case .enterAction:
            return .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .getYield, .enabledYields:
            return .requestPlain
        case .enterAction(let request):
            return .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        ["X-API-KEY": apiKey]
    }
}
