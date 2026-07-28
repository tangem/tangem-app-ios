//
//  TangemPayAvailabilityResponse.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayAvailabilityResponse: Decodable {
    public let channels: [TangemPayDistributionChannel]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawChannels = try container.decode([String].self, forKey: .channels)
        channels = rawChannels.compactMap(TangemPayDistributionChannel.init(rawValue:))
    }

    public enum CodingKeys: String, CodingKey {
        case channels
    }
}

public enum TangemPayDistributionChannel: String {
    case banner = "BANNER"
    case details = "DETAILS"
    case visaVirtualAccount = "VISA_VIRTUAL_ACCOUNT"
}
