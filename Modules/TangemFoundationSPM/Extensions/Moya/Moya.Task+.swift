//
//  Moya.Task+.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

// [REDACTED_TODO_COMMENT]
#if !SWIFT_PACKAGE
import Moya
import struct Alamofire.URLEncoding

public extension Moya.Task {
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
            assertionFailure("Moya.Task request parameters catch error \(error)")
            return .requestPlain
        }
    }
}
#endif // !SWIFT_PACKAGE
