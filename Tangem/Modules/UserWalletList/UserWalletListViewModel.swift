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

    var bottomSheetHeightUpdateCallback: ((ResizeSheetAction) -> ())?

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
        multiCurrencyModels = userWalletListService.models.filter { $0.isMultiWallet }
        singleCurrencyModels = userWalletListService.models.filter { !$0.isMultiWallet }
    }

    func onUserWalletTapped(_ userWallet: UserWallet) {
        setSelectedWallet(userWallet)
    }

    func addUserWallet() {
        scanCardInternal { [weak self] cardModel in
            self?.processScannedCard(cardModel)
        }
    }

    func tryAgain() {
        Analytics.log(.tryAgainTapped)
        addUserWallet()
    }

    func requestSupport() {
        Analytics.log(.supportTapped)
        failedCardScanTracker.resetCounter()

        coordinator.dismissUserWalletList()

        let dismissingDelay = 0.6
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissingDelay) {
            self.coordinator.openMail(with: self.failedCardScanTracker, emailType: .failedToScanCard, recipient: EmailConfig.default.recipient)
        }
    }

    func editUserWallet(_ userWallet: UserWallet) {
        #warning("l10n")
        let alert = UIAlertController(title: "Rename Wallet", message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "common_cancel".localized, style: .cancel) { _ in }
        alert.addAction(cancelAction)

        var nameTextField: UITextField?
        alert.addTextField { textField in
            nameTextField = textField
            nameTextField?.placeholder = "Wallet name"
            nameTextField?.text = userWallet.name
            nameTextField?.clearButtonMode = .whileEditing
            nameTextField?.autocapitalizationType = .sentences
        }

        let acceptButton = UIAlertAction(title: "common_ok".localized, style: .default) { [weak self, nameTextField] _ in
            var newUserWallet = userWallet
            newUserWallet.name = nameTextField?.text ?? ""

            let _ = self?.userWalletListService.save(newUserWallet)
            self?.updateModels()
        }
        alert.addAction(acceptButton)

        UIApplication.modalFromTop(alert)
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

        let oldModelSections = [multiCurrencyModels, singleCurrencyModels]

        userWalletListService.delete(userWallet)
        multiCurrencyModels.removeAll { $0.userWallet.userWalletId == userWallet.userWalletId }
        singleCurrencyModels.removeAll { $0.userWallet.userWalletId == userWallet.userWalletId }

        if let newSelectedUserWallet = newSelectedUserWallet {
            setSelectedWallet(newSelectedUserWallet)
        }

        if userWalletListService.isEmpty {
            AppSettings.shared.saveUserWallets = false
            coordinator.popToRoot()
        } else {
            updateHeight(oldModelSections: oldModelSections)
        }
    }

    private func scanCardInternal(_ completion: @escaping (CardViewModel) -> Void) {
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

                completion(cardModel)
            }
            .store(in: &bag)
    }

    private func processScannedCard(_ cardModel: CardViewModel) {
        let userWallet = cardModel.userWallet

        if userWalletListService.contains(userWallet) {
            return
        }

        let oldModelSections = [multiCurrencyModels, singleCurrencyModels]

        if userWalletListService.save(cardModel.userWallet) {
            let newModel = CardViewModel(userWallet: userWallet)
            if newModel.isMultiWallet {
                multiCurrencyModels.append(newModel)
            } else {
                singleCurrencyModels.append(newModel)
            }
            newModel.getCardInfo()
            newModel.updateState()

            setSelectedWallet(userWallet)

            updateHeight(oldModelSections: oldModelSections)
        }
    }

    private func setSelectedWallet(_ userWallet: UserWallet) {
        guard selectedUserWalletId != userWallet.userWalletId else {
            return
        }

        let completion: (UserWallet) -> Void = { [weak self] userWallet in
            self?.selectedUserWalletId = userWallet.userWalletId
            self?.userWalletListService.selectedUserWalletId = userWallet.userWalletId
            self?.coordinator.didTapUserWallet(userWallet: userWallet)
        }

        if !userWallet.isLocked {
            completion(userWallet)
            return
        }

        scanCardInternal { [weak self] cardModel in
            self?.userWalletListService.unlockWithCard(cardModel.userWallet) { result in
                guard case .success = result else {
                    return
                }

                guard let selectedModel = self?.userWalletListService.models.first(where: { $0.userWallet.userWalletId == userWallet.userWalletId }) else {
                    return
                }

                let userWallet = selectedModel.userWallet

                selectedModel.getCardInfo()
                selectedModel.updateState()

                self?.updateModels()

                completion(userWallet)
            }
        }
    }

    private func updateHeight(oldModelSections: [[CardViewModel]]) {
        let newModelSections = [multiCurrencyModels, singleCurrencyModels]

        let cellHeight = UserWalletListCellView.hardcodedHeight
        let headerHeight = UserWalletListHeaderView.hardcodedHeight

        let oldNumberOfModels = oldModelSections.reduce(into: 0) { $0 += $1.count }
        let newNumberOfModels = newModelSections.reduce(into: 0) { $0 += $1.count }

        let oldNumberOfSections = oldModelSections.filter { !$0.isEmpty }.count
        let newNumberOfSections = newModelSections.filter { !$0.isEmpty }.count

        let heightDifference = cellHeight * Double(newNumberOfModels - oldNumberOfModels) + headerHeight * Double(newNumberOfSections - oldNumberOfSections)

        bottomSheetHeightUpdateCallback?(.changeHeight(byValue: heightDifference))
    }
}
