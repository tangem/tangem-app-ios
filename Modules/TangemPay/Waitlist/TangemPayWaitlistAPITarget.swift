//
//  TangemPayWaitlistAPITarget.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct TangemPayWaitlistAPITarget: TargetType {
    let target: Target
    let apiType: VisaAPIType
    let encoder: JSONEncoder

    var baseURL: URL {
        apiType.bffBaseURL
    }

    var path: String {
        switch target {
        case .joinWaitlist:
            return "waitlist"
        }
    }

    var method: Moya.Method {
        .post
    }

    var task: Moya.Task {
        switch target {
        case .joinWaitlist(let request, _):
            return .requestCustomJSONEncodable(request, encoder: encoder)
        }
    }

    var headers: [String: String]? {
        switch target {
        case .joinWaitlist(_, let idempotencyKey):
            return [Constants.idempotencyKeyHeader: idempotencyKey]
        }
    }
}

extension TangemPayWaitlistAPITarget {
    enum Target {
        case joinWaitlist(request: TangemPayJoinWaitlistRequest, idempotencyKey: String)
    }
}

private extension TangemPayWaitlistAPITarget {
    enum Constants {
        static let idempotencyKeyHeader = "X-Idempotency-Key"
    }
}

extension TangemPayWaitlistAPITarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        false
    }
}
