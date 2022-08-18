//
//  UserWalletListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class UserWalletListViewModel: ObservableObject {
    // MARK: - ViewState
    @Published var selectedUserWalletId: Data?
    @Published var multiCurrencyModels: [CardViewModel] = []
    @Published var singleCurrencyModels: [CardViewModel] = []
    @Published var isScanningCard = false
    @Published var error: AlertBinder?
    @Published var showTroubleshootingView: Bool = false

    // MARK: - Dependencies

    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    @Injected(\.userWalletListService) private var userWalletListService: UserWalletListService
    @Injected(\.failedScanTracker) var failedCardScanTracker: FailedScanTrackable

    private unowned let coordinator: UserWalletListRoutable
    private var bag: Set<AnyCancellable> = []
    private var initialized = false

    init(
        coordinator: UserWalletListRoutable
    ) {
        self.coordinator = coordinator
        updateModels()
    }

    func onAppear() {
        if !initialized {
            initialized = true

            for model in (multiCurrencyModels + singleCurrencyModels) {
                model.getCardInfo()
                model.updateState()
            }

            selectedUserWalletId = userWalletListService.selectedUserWalletId
        }
    }

    func updateModels() {
        multiCurrencyModels = userWalletListService.models.filter { $0.userWallet.isMultiCurrency }
        singleCurrencyModels = userWalletListService.models.filter { !$0.userWallet.isMultiCurrency }
    }

    func onUserWalletTapped(_ userWallet: UserWallet) {
        setSelectedWallet(userWallet)
    }

    func addCard() {
        isScanningCard = true

        cardsRepository.scanPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Failed to scan card: \(error)")
                    self?.isScanningCard = false
                    self?.failedCardScanTracker.recordFailure()

                    if self?.failedCardScanTracker.shouldDisplayAlert ?? false {
                        self?.showTroubleshootingView = true
                    } else {
                        switch error.toTangemSdkError() {
                        case .unknownError, .cardVerificationFailed:
                            self?.error = error.alertBinder
                        default:
                            break
                        }
                    }
                }
            } receiveValue: { [weak self] cardModel in
                self?.isScanningCard = false
                self?.failedCardScanTracker.resetCounter()
                self?.processScannedCard(cardModel)
            }
            .store(in: &bag)
    }

    func tryAgain() {
        Analytics.log(.tryAgainTapped)
        addCard()
    }

    func requestSupport() {
        Analytics.log(.supportTapped)
        failedCardScanTracker.resetCounter()
        coordinator.openMail(with: failedCardScanTracker)
    }

    func editWallet(_ userWallet: UserWallet) {
        let vc: UIAlertController = UIAlertController(title: "Rename Wallet", message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "common_cancel".localized, style: .cancel) { _ in

        }
        vc.addAction(cancelAction)

        var nameTextField: UITextField?
        vc.addTextField { textField in
            nameTextField = textField
            #warning("l10n")
            nameTextField?.placeholder = "Wallet name"
            nameTextField?.text = userWallet.name
            nameTextField?.clearButtonMode = .whileEditing
            nameTextField?.autocapitalizationType = .sentences
        }

        let acceptButton = UIAlertAction(title: "common_ok".localized, style: .default) { [weak self, nameTextField] _ in
            let name = nameTextField?.text ?? ""
            self?.userWalletListService.setName(userWallet, name: name)
            self?.updateModels()
        }
        vc.addAction(acceptButton)

        UIApplication.modalFromTop(vc)
    }

    func deleteUserWallet(_ userWallet: UserWallet) {
        let userWalletId = userWallet.userWalletId
        let models = userWalletListService.models

        let newSelectedUserWallet: UserWallet?

        if userWalletId == selectedUserWalletId,
           let deletedUserWalletIndex = models.firstIndex(where: { $0.userWallet.userWalletId == userWalletId })
        {
            if deletedUserWalletIndex != (models.count - 1) {
                newSelectedUserWallet = models[deletedUserWalletIndex + 1].userWallet
            } else if deletedUserWalletIndex != 0 {
                newSelectedUserWallet = models[deletedUserWalletIndex - 1].userWallet
            } else {
                newSelectedUserWallet = nil
            }
        } else {
            newSelectedUserWallet = nil
        }

        userWalletListService.deleteWallet(userWallet)
        multiCurrencyModels.removeAll { $0.userWallet.userWalletId == userWallet.userWalletId }
        singleCurrencyModels.removeAll { $0.userWallet.userWalletId == userWallet.userWalletId }

        if let newSelectedUserWallet = newSelectedUserWallet {
            setSelectedWallet(newSelectedUserWallet)
        }

        if userWalletListService.isEmpty {
            AppSettings.shared.saveUserWallets = false
            coordinator.popToRoot()
        }
    }

    private func processScannedCard(_ cardModel: CardViewModel) {
        let cardInfo = cardModel.cardInfo
        let card = cardInfo.card

        let walletData: DefaultWalletData

        if let cardInfoWalletData = cardInfo.walletData, cardInfoWalletData.blockchain != "ANY" {
            walletData = .note(cardInfoWalletData)
        } else {
            walletData = .none
        }
        // [REDACTED_TODO_COMMENT]

        let name: String = cardModel.cardInfo.name
        let accessCode = cardInfo.accessCode

        let userWallet = UserWallet(userWalletId: card.cardPublicKey, name: name, card: card, walletData: walletData, artwork: nil, keys: cardInfo.derivedKeys, isHDWalletAllowed: card.settings.isHDWalletAllowed, accessCode: accessCode)

        if userWalletListService.contains(userWallet) {
            return
        }

        if userWalletListService.save(userWallet) {
            let newModel = CardViewModel(userWallet: userWallet)
            if userWallet.isMultiCurrency {
                multiCurrencyModels.append(newModel)
            } else {
                singleCurrencyModels.append(newModel)
            }
            newModel.getCardInfo()
            newModel.updateState()

            setSelectedWallet(userWallet)
        }
    }

    private func setSelectedWallet(_ userWallet: UserWallet) {
        self.selectedUserWalletId = userWallet.userWalletId
        userWalletListService.selectedUserWalletId = userWallet.userWalletId
        self.coordinator.didTapUserWallet(userWallet: userWallet)
    }
}
