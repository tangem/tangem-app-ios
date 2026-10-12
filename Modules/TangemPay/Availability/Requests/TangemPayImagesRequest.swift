//
//  TangemPayImagesRequest.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TangemPayImagesRequest: Encodable {
    let deeplinkValue: String

    enum CodingKeys: String, CodingKey {
        case deeplinkValue = "deeplink_value"
    }
}
