//
//  ReferralViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import class UIKit.UIPasteboard

class ReferralViewModel: ObservableObject {
    @Published var isProcessingRequest: Bool = false
    @Published private(set) var referralProgramInfo: ReferralProgramInfo?

    var award: String {
        guard
            let info = referralProgramInfo,
            let awardToken = info.conditions.tokens.first
        else {
            return ""
        }

        return String(format: "referral_point_discount_description_value".localized, "\(info.conditions.award) \(awardToken.symbol)")
    }

    var awardDescriptionSuffix: String {
        let format = "referral_point_currencies_description_suffix".localized
        var addressContent = ""
        if let address = referralProgramInfo?.referral?.address {
            let addressFormatter = AddressFormatter(address: address)
            addressContent = addressFormatter.truncated()
        }

        return " " + String(format: format, addressContent)
    }

    var discount: String {
        guard let info = referralProgramInfo else {
            return ""
        }

        return String(format: "referral_point_discount_description_value".localized, "\(info.conditions.discount)\(info.conditions.discountType.symbol)")
    }

    var numberOfWalletsBought: String {
        let stringFormat = "referral_wallets_purchased_count".localized
        guard let info = referralProgramInfo?.referral else {
            return String.localizedStringWithFormat(stringFormat, 0)
        }

        return String.localizedStringWithFormat(stringFormat, info.walletPurchase)
    }

    var promoCode: String {
        guard let info = referralProgramInfo?.referral else {
            return ""
        }

        return info.promoCode
    }

    var touButtonPrefix: String {
        if referralProgramInfo?.referral == nil {
            return "referral_tou_not_enroled_prefix".localized + " "
        }

        return "referral_tou_enroled_prefix".localized + " "
    }

    var isProgramInfoLoaded: Bool { referralProgramInfo != nil }
    var isAlreadyReferral: Bool { referralProgramInfo?.referral != nil }

    var referralInfo: ReferralProgramInfo.Referral? {
        referralProgramInfo?.referral
    }

    private let coordinator: ReferralRoutable

    init(coordinator: ReferralRoutable, json: String = "") {
        self.coordinator = coordinator
        let jsonDecoder = JSONDecoder()
        referralProgramInfo = try? jsonDecoder.decode(ReferralProgramInfo.self, from: json.data(using: .utf8)!)
    }

    // Temp solution. Will be updated in [REDACTED_INFO]
    static func mock(_ mock: ReferralMock, with coordinator: ReferralRoutable) -> ReferralViewModel {
        .init(coordinator: coordinator, json: mock.json)
    }

    func openTou() {
        // [REDACTED_TODO_COMMENT]
    }

    func participateInReferralProgram() {
        // [REDACTED_TODO_COMMENT]
    }

    func copyPromoCode() {
        UIPasteboard.general.string = referralProgramInfo?.referral?.promoCode
    }

    func sharePromoCode() {

    }
}
