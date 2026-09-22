//
//  TangemPayImagesResponse.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public typealias TangemPayImagesResponse = [VisaCustomerInfoResponse.TariffPlan.Image]

public extension Sequence where Element == VisaCustomerInfoResponse.TariffPlan.Image {
    var mainImageURL: URL? {
        first { $0.type == .main }.flatMap { URL(string: $0.url) }
    }
}
