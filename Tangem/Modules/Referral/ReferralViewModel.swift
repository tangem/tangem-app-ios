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
    @Published var showCodeCopiedToast: Bool = false

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

        let token = award.token

        guard let address = cardModel.wallets.first(where: { $0.blockchain == blockchain })?.address else {
            await requestDerivation(for: blockchain, with: token)
            return
        }

        saveToStorageIfNeeded(token, for: blockchain)

        isProcessingRequest = true
        do {
            let referralProgramInfo = try await runInTask {
                try await self.tangemApiService.participateInReferralProgram(using: token, for: address, with: self.userWalletId.hexString)
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
        showCodeCopiedToast = true
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

    @MainActor
    private func requestDerivation(for blockchain: Blockchain, with referralToken: ReferralProgramInfo.Token) async {
        let network = cardModel.getBlockchainNetwork(for: blockchain, derivationPath: nil)
        let token = convertToStorageToken(from: referralToken)

        let storageEntry = StorageEntry(blockchainNetwork: network, token: token)
        if let model = cardModel.walletModels.first(where: { $0.blockchainNetwork == network }),
           let token {
            model.addTokens([token])
        }

        cardModel.add(entries: [storageEntry]) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                runTask(self.participateInReferralProgram)
            case .failure(let error):
                if case .userCancelled = error.toTangemSdkError() {
                    return
                }

                self.errorAlert = error.alertBinder
            }
        }
    }

    private func saveToStorageIfNeeded(_ referralToken: ReferralProgramInfo.Token, for blockchain: Blockchain) {
        let network = cardModel.getBlockchainNetwork(for: blockchain, derivationPath: nil)
        guard
            let storageToken = convertToStorageToken(from: referralToken),
            let userWalletModel = cardModel.userWalletModel
        else {
            return
        }

        var savedEntries = userWalletModel.getSavedEntries()

        if let savedNetworkIndex = savedEntries.firstIndex(where: { $0.blockchainNetwork == network }),
           !savedEntries[savedNetworkIndex].tokens.contains(where: { $0 == storageToken }) {

            savedEntries[savedNetworkIndex].tokens.append(storageToken)
            cardModel.userWalletModel?.update(entries: savedEntries)
        }
    }

    private func convertToStorageToken(from token: ReferralProgramInfo.Token) -> Token? {
        guard
            let contractAddress = token.contractAddress,
            let decimalCount = token.decimalCount
        else {
            return nil
        }

        return Token(name: token.name,
                     symbol: token.symbol,
                     contractAddress: contractAddress,
                     decimalCount: decimalCount,
                     id: token.id)
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
        var tokenName = ""
        if let address = referralProgramInfo?.referral?.address {
            let addressFormatter = AddressFormatter(address: address)
            addressContent = " \(addressFormatter.truncated())"
        }

        if let token = referralProgramInfo?.conditions.awards.first?.token,
           let blockchain = Blockchain(from: token.networkId) {
            tokenName = blockchain.displayName
        }

        return " " + String(format: format, tokenName, addressContent)
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

    var shareLink: String {
        guard let referralInfo = referralProgramInfo?.referral else {
            return ""
        }

        return String(format: "referral_share_link".localized, referralInfo.shareLink)
    }

    var isProgramInfoLoaded: Bool { referralProgramInfo != nil }
    var isAlreadyReferral: Bool { referralProgramInfo?.referral != nil }
}

// MARK: - Navigation
extension ReferralViewModel {
    func openTOS() {
        guard
            let link = referralProgramInfo?.conditions.tosLink,
            let url = URL(string: link)
        else {
            print("Failed to create link")
            return
        }

        coordinator.openTOS(with: url)
    }
}
