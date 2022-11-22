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
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Published var isProcessingRequest: Bool = false
    @Published private(set) var referralProgramInfo: ReferralProgramInfo?
    @Published var errorAlert: AlertBinder?

    private unowned let coordinator: ReferralRoutable
    private let cardModel: CardViewModel
    private let userWalletId: Data

    init(cardModel: CardViewModel, userWalletId: Data, coordinator: ReferralRoutable) {
        self.cardModel = cardModel
        self.userWalletId = userWalletId
        self.coordinator = coordinator

        runTask(loadReferralInfo)
    }

    @MainActor
    func participateInReferralProgram() async {
        guard
            let award = referralProgramInfo?.conditions.awards.first,
            let blockchain = Blockchain(from: award.token.networkId)
        else {
            errorAlert = AlertBuilder.makeOkErrorAlert(message: "referral_error_failed_to_load_info".localized,
                                                       okAction: coordinator.dismiss)
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
                try await self.tangemApiService.participateInReferralProgram(using: award.token, for: address, with: self.userWalletId.hexString)
            }
            self.referralProgramInfo = referralProgramInfo
        } catch {
            let format = "referral_error_failed_to_participate".localized
            errorAlert = AlertBuilder.makeOkErrorAlert(message: String(format: format, error.localizedDescription))
        }

        isProcessingRequest = false
    }

    func copyPromoCode() {
        UIPasteboard.general.string = referralProgramInfo?.referral?.promoCode
    }

    func sharePromoCode() {

    }

    @MainActor
    private func loadReferralInfo() async {
        do {
            let referralProgramInfo = try await runInTask {
                try await self.tangemApiService.loadReferralProgramInfo(for: self.userWalletId.hexString)
            }
            self.referralProgramInfo = referralProgramInfo
        } catch {
            let format = "referral_error_failed_to_load_info_with_reason".localized
            self.errorAlert = AlertBuilder.makeOkErrorAlert(message: String(format: format, error.localizedDescription),
                                                            okAction: self.coordinator.dismiss)
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

    var tosButtonPrefix: String {
        if referralProgramInfo?.referral == nil {
            return "referral_tos_not_enroled_prefix".localized + " "
        }

        return "referral_tos_enroled_prefix".localized + " "
    }

    var isProgramInfoLoaded: Bool { referralProgramInfo != nil }
    var isAlreadyReferral: Bool { referralProgramInfo?.referral != nil }
}

// MARK: - Navigation
extension ReferralViewModel {
    func openTos() {
        guard
            let link = referralProgramInfo?.conditions.tosLink,
            let url = URL(string: link)
        else {
            print("Failed to create link")
            return
        }

        coordinator.openTos(with: url)
    }
}
