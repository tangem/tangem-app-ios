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
    @Published var isLoading: Bool = false
    @Published var referralProgramInfo: ReferralProgramInfo?

    var award: String {
        guard
            let info = referralProgramInfo,
            let awardToken = info.conditions.tokens.first
        else {
            return ""
        }

        return String(format: "referral_point_discount_description_value".localized, "\(info.conditions.award) \(awardToken.symbol)")
    }

    var discount: String {
        guard let info = referralProgramInfo else {
            return ""
        }

        return "\(info.conditions.discount)\(info.conditions.discountType.symbol)"
    }

    var numberOfWalletsBought: String {
        let stringFormat = "referral_wallets_bought"
        guard let info = referralProgramInfo?.referral else {
            return String(format: stringFormat, 0)
        }

        return String(format: stringFormat, info.walletPurchase)
    }

    var promoCode: String {
        guard let info = referralProgramInfo?.referral else {
            return ""
        }

        return info.promoCode
    }

    var touButtonPrefix: String {
        if referralProgramInfo?.referral == nil {
            return "referral_tou_not_enroled_prefix"
        }

        return "referral_tou_enroled_prefix"
    }

    var isProgramInfoLoaded: Bool { referralProgramInfo != nil }
    var isAlreadyReferral: Bool { referralProgramInfo?.referral != nil }

    var referralInfo: ReferralInfo? {
        referralProgramInfo?.referral
    }

    private let coordinator: ReferralRoutable

    init(coordinator: ReferralRoutable, json: String = "") {
        self.coordinator = coordinator
        let jsonDecoder = JSONDecoder()
        referralProgramInfo = try! jsonDecoder.decode(ReferralProgramInfo.self, from: json.data(using: .utf8)!)
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
