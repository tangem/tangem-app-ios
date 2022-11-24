//
//  UserWalletListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class UserWalletListViewModel: ObservableObject, Identifiable {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.failedScanTracker) var failedCardScanTracker: FailedScanTrackable

    // MARK: - ViewState
    @Published var selectedUserWalletId: Data?
    @Published var multiCurrencyModels: [UserWalletListCellViewModel] = []
    @Published var singleCurrencyModels: [UserWalletListCellViewModel] = []
    @Published var isScanningCard = false
    @Published var error: AlertBinder?
    @Published var showTroubleshootingView: Bool = false
    @Published var showingDeleteConfirmation: Bool = false

    // MARK: - Dependencies

    var unlockAllButtonLocalizationKey: LocalizedStringKey {
        switch BiometricAuthorizationUtils.biometryType {
        case .faceID:
            return "user_wallet_list_unlock_all_face_id"
        case .touchID:
            return "user_wallet_list_unlock_all_touch_id"
        case .none:
            return ""
        @unknown default:
            return ""
        }
    }

    var isUnlocked: Bool {
        userWalletRepository.isUnlocked
    }

    private unowned let coordinator: UserWalletListRoutable
    private var bag: Set<AnyCancellable> = []
    private var userWalletIdToBeDeleted: Data?

    init(
        coordinator: UserWalletListRoutable
    ) {
        self.coordinator = coordinator

        Analytics.log(.myWalletsScreenOpened)
        selectedUserWalletId = userWalletRepository.selectedUserWalletId
        updateModels()

        bind()
    }

    func bind() {
        userWalletRepository
            .eventProvider
            .sink { [weak self] event in
                switch event {
                case .locked:
                    break
                case .scan(let isScanning):
                    self?.isScanningCard = isScanning
                case .updated(let userWalletModel):
                    self?.update(userWalletModel: userWalletModel)
                case .deleted(let userWalletId):
                    self?.delete(userWalletId: userWalletId)
                case .selected(let userWallet):
                    self?.setSelectedWallet(userWallet)
                case .inserted:
                    break
                }
            }
            .store(in: &bag)
    }

    func unlockAllWallets() {
        Analytics.log(.buttonUnlockAllWithFaceID)

        userWalletRepository.unlock(with: .biometry) { [weak self] result in
            if case .error = result {
                return
            }

            self?.updateModels()
        }
    }

    func addUserWallet() {
        Analytics.log(.buttonScanNewCard)

        userWalletRepository.add { [weak self] result in
            guard
                let self,
                let result
            else {
                return
            }

            switch result {
            case .troubleshooting:
                self.showTroubleshootingView = true
            case .onboarding(let input):
                self.openOnboarding(with: input)
            case .error(let error):
                self.error = error.alertBinder
            case .success(let cardModel):
                self.add(cardModel: cardModel)
            }
        }
    }

    func tryAgain() {
        addUserWallet()
    }

    func requestSupport() {
        Analytics.log(.buttonRequestSupport)
        failedCardScanTracker.resetCounter()

        coordinator.dismissUserWalletList()

        let dismissingDelay = 0.6
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissingDelay) {
            self.coordinator.openMail(with: self.failedCardScanTracker, emailType: .failedToScanCard, recipient: EmailConfig.default.recipient)
        }
    }

    func editUserWallet(_ viewModel: UserWalletListCellViewModel) {
        Analytics.log(.buttonEditWalletTapped)

        let alert = UIAlertController(title: "user_wallet_list_rename_popup_title".localized, message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "common_cancel".localized, style: .cancel) { _ in }
        alert.addAction(cancelAction)

        var nameTextField: UITextField?
        alert.addTextField { textField in
            nameTextField = textField
            nameTextField?.placeholder = "user_wallet_list_rename_popup_placeholder".localized
            nameTextField?.text = viewModel.userWallet.name
            nameTextField?.clearButtonMode = .whileEditing
            nameTextField?.autocapitalizationType = .sentences
        }

        let acceptButton = UIAlertAction(title: "common_ok".localized, style: .default) { [weak self, nameTextField] _ in
            let newName = nameTextField?.text ?? ""

            guard viewModel.userWallet.name != newName else { return }

            var newUserWallet = viewModel.userWallet
            newUserWallet.name = newName

            self?.userWalletRepository.save(newUserWallet)
        }
        alert.addAction(acceptButton)

        UIApplication.modalFromTop(alert)
    }

    func showDeletionConfirmation(_ viewModel: UserWalletListCellViewModel) {
        Analytics.log(.buttonDeleteWalletTapped)

        showingDeleteConfirmation = true
        userWalletIdToBeDeleted = viewModel.userWalletId
    }

    func didCancelWalletDeletion() {
        userWalletIdToBeDeleted = nil
    }

    func didConfirmWalletDeletion() {
        let viewModels = (multiCurrencyModels + singleCurrencyModels)
        guard let viewModel = viewModels.first(where: { $0.userWalletId == userWalletIdToBeDeleted }) else {
            return
        }

        userWalletRepository.delete(viewModel.userWallet)
    }

    private func setSelectedWallet(_ userWallet: UserWallet) {
        guard let model = userWalletRepository.models.first(where: {
            $0.userWallet?.userWalletId == userWallet.userWalletId
        }) else {
            return
        }

        self.selectedUserWalletId = userWallet.userWalletId
        updateSelectedWalletModel()
    }

    private func updateModels() {
        let oldModels = multiCurrencyModels + singleCurrencyModels
        let totalBalanceProviders = Dictionary(oldModels.map {
            ($0.userWalletId, $0.totalBalanceProvider)
        }, uniquingKeysWith: { v1, _ in
            v1
        })

        multiCurrencyModels = userWalletRepository.models
            .filter { $0.isMultiWallet }
            .compactMap { $0.userWalletModel }
            .map {
                mapToUserWalletListCellViewModel(userWalletModel: $0, totalBalanceProvider: totalBalanceProviders[$0.userWallet.userWalletId])
            }

        singleCurrencyModels = userWalletRepository.models
            .filter { !$0.isMultiWallet }
            .compactMap { $0.userWalletModel }
            .map {
                mapToUserWalletListCellViewModel(userWalletModel: $0, totalBalanceProvider: totalBalanceProviders[$0.userWallet.userWalletId])
            }
    }

    private func update(userWalletModel: UserWalletModel) {
        let userWalletId = userWalletModel.userWallet.userWalletId

        if let index = multiCurrencyModels.firstIndex(where: { $0.userWalletId == userWalletId }) {
            multiCurrencyModels[index] = mapToUserWalletListCellViewModel(
                userWalletModel: userWalletModel,
                totalBalanceProvider: multiCurrencyModels[index].totalBalanceProvider
            )
        } else if let index = singleCurrencyModels.firstIndex(where: { $0.userWalletId == userWalletId }) {
            singleCurrencyModels[index] = mapToUserWalletListCellViewModel(
                userWalletModel: userWalletModel,
                totalBalanceProvider: singleCurrencyModels[index].totalBalanceProvider
            )
        }
    }

    private func delete(userWalletId: Data) {
        userWalletIdToBeDeleted = nil

        multiCurrencyModels.removeAll { $0.userWalletId == userWalletId }
        singleCurrencyModels.removeAll { $0.userWalletId == userWalletId }

        if userWalletRepository.isEmpty && AppSettings.shared.saveUserWallets {
            AppSettings.shared.saveUserWallets = false
            coordinator.dismissUserWalletList()
            coordinator.popToRoot()
        }
    }

    private func updateSelectedWalletModel() {
        let models = multiCurrencyModels + singleCurrencyModels
        for model in models {
            model.isSelected = selectedUserWalletId == model.userWalletId
        }
    }

    private func openOnboarding(with input: OnboardingInput) {
        DispatchQueue.main.async {
            self.coordinator.openOnboarding(with: input)
        }
    }

    func add(cardModel: CardViewModel) {
        guard
            let cellModel = cardModel.userWalletModel.map({ mapToUserWalletListCellViewModel(userWalletModel: $0) }),
            let userWallet = cardModel.userWallet
        else {
            return
        }

        if cardModel.isMultiWallet {
            multiCurrencyModels.append(cellModel)
        } else {
            singleCurrencyModels.append(cellModel)
        }

        setSelectedWallet(userWallet)
    }

    private func mapToUserWalletListCellViewModel(userWalletModel: UserWalletModel, totalBalanceProvider: TotalBalanceProviding? = nil) -> UserWalletListCellViewModel {
        let userWallet = userWalletModel.userWallet
        let config = UserWalletConfigFactory(userWallet.cardInfo()).makeConfig()
        let subtitle: String = {
            if let embeddedBlockchain = config.embeddedBlockchain {
                return embeddedBlockchain.blockchainNetwork.blockchain.displayName
            }

            return String.localizedStringWithFormat("card_label_card_count".localized, config.cardsCount)
        }()

        return UserWalletListCellViewModel(
            userWalletModel: userWalletModel,
            subtitle: subtitle,
            isMultiWallet: config.hasFeature(.multiCurrency),
            isUserWalletLocked: userWallet.isLocked,
            isSelected: selectedUserWalletId == userWallet.userWalletId,
            totalBalanceProvider: totalBalanceProvider ?? TotalBalanceProvider(userWalletModel: userWalletModel, userWalletAmountType: nil, totalBalanceAnalyticsService: nil),
            cardImageProvider: CardImageProvider()
        ) { [weak self] in
            if userWallet.isLocked {
                Analytics.log(.walletUnlockTapped)
            }
            self?.userWalletRepository.setSelectedUserWalletId(userWallet.userWalletId)
        }
    }
}
