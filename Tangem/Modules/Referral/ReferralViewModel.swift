//
//  ReferralViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import BlockchainSdk

class ReferralViewModel: ObservableObject {
    @Published var isProcessingRequest: Bool = false
    @Published private(set) var referralProgramInfo: ReferralProgramInfo?
    @Published var errorAlert: AlertBinder?

    private unowned let coordinator: ReferralRoutable
    private let referralService: ReferralService
    private let cardModel: CardViewModel

    init(coordinator: ReferralRoutable, referralService: ReferralService, cardModel: CardViewModel) {
        self.coordinator = coordinator
        self.referralService = referralService
        self.cardModel = cardModel

        loadReferralInfo()
    }

    @MainActor
    func participateInReferralProgram() async {
        guard
            let award = referralProgramInfo?.conditions.awards.first,
            let blockchain = Blockchain(from: award.token.networkId)
        else {
            errorAlert = AlertBuilder.makeOkErrorAlert(message: "Failed to load")
            return
        }

        // [REDACTED_TODO_COMMENT]
        guard let address = cardModel.wallets.first(where: { $0.blockchain == blockchain })?.address else {
            requestDerivation()
            return
        }

        isProcessingRequest = true
        do {
            let referralProgramInfo = try await runInTask {
                let prog = try await self.referralService.participateInReferralProgram(using: award.token, with: address)
                return prog
            }
            self.referralProgramInfo = referralProgramInfo
        } catch {
            errorAlert = error.alertBinder
        }

        isProcessingRequest = false
    }

    func openTou() {
        // [REDACTED_TODO_COMMENT]
    }

    func copyPromoCode() {
        UIPasteboard.general.string = referralProgramInfo?.referral?.promoCode
    }

    func sharePromoCode() {

    }

    private func loadReferralInfo() {
        Task {
            do {
                let referralProgramInfo = try await self.referralService.loadReferralProgramInfo()
                await runOnMain {
                    self.referralProgramInfo = referralProgramInfo
                }
            } catch {
                await runOnMain {
                    errorAlert = error.alertBinder
                }
            }
        }
    }

    private func requestDerivation() {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: UI stuff
extension ReferralViewModel {
    var award: String {
        guard
            let info = referralProgramInfo,
            let award = info.conditions.awards.first
        else {
            return ""
        }

        return "\(award.amount) \(award.token.symbol)"
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

        return String(format: "referral_point_discount_description_value".localized, "\(info.conditions.discount.amount)\(info.conditions.discount.type.symbol)")
    }

    var numberOfWalletsBought: String {
        let stringFormat = "referral_wallets_purchased_count".localized
        guard let info = referralProgramInfo?.referral else {
            return String.localizedStringWithFormat(stringFormat, 0)
        }

        return String.localizedStringWithFormat(stringFormat, info.walletsPurchased)
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
}
