//
//  SurveySparrowTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct SurveySparrowTarget: TargetType {
    let type: RequestType
    let baseURL: URL

    var path: String { "/v3/responses" }

    var method: Moya.Method {
        switch type {
        case .checkExisting: .get
        case .submit: .post
        }
    }

    var task: Moya.Task {
        switch type {
        case .checkExisting(let request):
            .requestParameters(request, encoding: URLEncoding.queryString)
        case .submit(let request):
            .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? { nil }
}

// MARK: - Request Type

extension SurveySparrowTarget {
    enum RequestType {
        case checkExisting(request: SurveySparrowDTO.CheckExisting.Request)
        case submit(request: SurveySparrowDTO.Submit.Request)
    }
}
