//
//  Moya.Task+.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import struct Alamofire.URLEncoding

public extension Moya.Task {
    /// `encodable` Encodable as URL parameters.
    static func requestParameters(
        _ encodable: Encodable,
        encoder: JSONEncoder = JSONEncoder(),
        encoding: ParameterEncoding = URLEncoding()
    ) -> Task {
        do {
            let data = try encoder.encode(encodable)
            let parameters = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return .requestParameters(parameters: parameters ?? [:], encoding: encoding)
        } catch {
            assertionFailure("Moya.Task request parameters caught an error: '\(error)'")
            return .requestPlain
        }
    }

    /// `body` Encodable as a body with `bodyEncoding` encoding, `urlParameters` Encodable as URL parameters.
    static func requestCompositeParameters(
        body: Encodable,
        urlParameters: Encodable,
        encoder: JSONEncoder = JSONEncoder(),
        bodyEncoding: ParameterEncoding = JSONEncoding.default
    ) -> Task {
        do {
            let bodyData = try encoder.encode(body)
            let bodyParameters = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]

            let urlParametersData = try encoder.encode(urlParameters)
            let urlParameters = try JSONSerialization.jsonObject(with: urlParametersData) as? [String: Any]

            return .requestCompositeParameters(
                bodyParameters: bodyParameters ?? [:],
                bodyEncoding: bodyEncoding,
                urlParameters: urlParameters ?? [:]
            )
        } catch {
            assertionFailure("Moya.Task request parameters caught an error: '\(error)'")
            return .requestPlain
        }
    }
}
