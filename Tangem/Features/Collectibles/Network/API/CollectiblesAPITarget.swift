//
//  CollectiblesAPITarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct CollectiblesAPITarget: Moya.TargetType {
    let baseURL: URL
    let target: Target

    enum Target {
        case categories
        case machines(CollectiblesDTO.MachinesRequest)
        case machine(externalID: String)
    }

    var path: String {
        switch target {
        case .categories:
            return "api/v1/machine/categories"
        case .machines:
            return "api/v1/machine/machines"
        case .machine(let externalID):
            return "api/v1/machine/\(externalID)"
        }
    }

    var method: Moya.Method {
        .get
    }

    var task: Moya.Task {
        switch target {
        case .categories, .machine:
            return .requestPlain

        case .machines(let request):
            return .requestParameters(request, encoding: URLEncoding.queryString)
        }
    }

    var headers: [String: String]? {
        nil
    }
}

extension CollectiblesAPITarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        false
    }
}
