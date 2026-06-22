//
//  TangemPayOrderType.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum TangemPayOrderType: String, Decodable {
    case cardIssueVirtualRainKyc = "CARD_ISSUE_VIRTUAL_RAIN_KYC"
    case cardIssueVirtualRainKycV2 = "CARD_ISSUE_VIRTUAL_RAIN_KYC_V2"
    case cardIssueVirtualRain = "CARD_ISSUE_VIRTUAL_RAIN"
    case unknown

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = TangemPayOrderType(rawValue: raw) ?? .unknown
    }
}

public extension TangemPayOrderType {
    static let cardIssueFamily: [String] = [
        cardIssueVirtualRain.rawValue,
        cardIssueVirtualRainKyc.rawValue,
        cardIssueVirtualRainKycV2.rawValue,
    ]
}
