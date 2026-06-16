//
//  SurveySparrowRatingProvider+Plugin.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya

extension SurveySparrowRatingProvider {
    struct Plugin: PluginType {
        let token: String

        func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
            var request = request
            request.headers.add(name: "Authorization", value: "Bearer \(token)")
            return request
        }
    }
}
