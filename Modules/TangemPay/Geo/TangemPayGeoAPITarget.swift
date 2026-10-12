//
//  TangemPayGeoAPITarget.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct TangemPayGeoAPITarget: TargetType {
    let target: Target
    let apiType: VisaAPIType

    var baseURL: URL {
        apiType.bffBaseURL
    }

    var path: String {
        switch target {
        case .countries:
            return "geo/countries"
        case .regions(let countryCode):
            return "geo/countries/\(countryCode)/regions"
        }
    }

    var method: Moya.Method {
        .get
    }

    var task: Moya.Task {
        .requestPlain
    }

    var headers: [String: String]? {
        nil
    }
}

extension TangemPayGeoAPITarget {
    enum Target {
        case countries
        case regions(countryCode: String)
    }
}

extension TangemPayGeoAPITarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        false
    }
}
