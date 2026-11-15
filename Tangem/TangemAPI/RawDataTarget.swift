//
//  RawDataTarget.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

/// Points at any third-party URL, so it stays out of `TangemApiTarget` and the providers that send Tangem headers.
struct RawDataTarget: TargetType {
    let url: URL

    var baseURL: URL { url }
    var path: String { "" }
    var method: Moya.Method { .get }
    var task: Moya.Task { .requestPlain }
    var headers: [String: String]? { nil }
    var validationType: ValidationType { .successCodes }
}

// MARK: - TargetTypeLogConvertible

extension RawDataTarget: TargetTypeLogConvertible {
    var requestDescription: String { url.path }
    var shouldLogResponseBody: Bool { false }
}
