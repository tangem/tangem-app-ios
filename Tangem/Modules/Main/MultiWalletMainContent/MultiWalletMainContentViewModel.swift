//
//  MultiWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import SwiftUI

final class MultiWalletMainContentViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var isLoadingTokenList: Bool = true
    @Published var sections: [MultiWalletTokenItemsSection] = []
    @Published var missingDerivationNotificationSettings: NotificationView.Settings? = nil
    @Published var missingBackupNotificationSettings: NotificationView.Settings? = nil
    @Published var notificationInputs: [NotificationViewInput] = []

    @Published var isScannerBusy = false
    @Published var error: AlertBinder? = nil

    var bottomOverlayViewModel: MainBottomOverlayViewModel? {
        guard canManageTokens else { return nil }

        return MainBottomOverlayViewModel(
            isButtonDisabled: false,
            buttonTitle: Localization.mainManageTokens,
            buttonAction: openManageTokens
        )
    }

    var isOrganizeTokensVisible: Bool {
        if sections.isEmpty {
            return false
        }

        let numberOfTokens = sections.reduce(0) { $0 + $1.tokenItemModels.count }
        let requiredNumberOfTokens = 2

        return numberOfTokens >= requiredNumberOfTokens
    }

    // MARK: - Dependencies

    private let userWalletModel: UserWalletModel
    private let userWalletNotificationManager: NotificationManager
    private unowned let coordinator: MultiWalletMainContentRoutable
    private var sectionsProvider: TokenListInfoProvider
    private let canManageTokens: Bool // [REDACTED_TODO_COMMENT]

    private var isUpdating = false
    private var bag = Set<AnyCancellable>()

    init(
        userWalletModel: UserWalletModel,
        userWalletNotificationManager: NotificationManager,
        coordinator: MultiWalletMainContentRoutable,
        sectionsProvider: TokenListInfoProvider,
        canManageTokens: Bool
    ) {
        self.userWalletModel = userWalletModel
        self.userWalletNotificationManager = userWalletNotificationManager
        self.coordinator = coordinator
        self.sectionsProvider = sectionsProvider
        self.canManageTokens = canManageTokens

        setup()
    }

    func onPullToRefresh(completionHandler: @escaping RefreshCompletionHandler) {
        if isUpdating {
            return
        }

        isUpdating = true
        userWalletModel.userTokenListManager.updateLocalRepositoryFromServer { [weak self] _ in
            self?.userWalletModel.walletModelsManager.updateAll(silent: true, completion: {
                self?.isUpdating = false
                completionHandler()
            })
        }
    }

    func deriveEntriesWithoutDerivation() {
        Analytics.log(.noticeScanYourCardTapped)
        isScannerBusy = true
        userWalletModel.userTokensManager.deriveIfNeeded { [weak self] _ in
            DispatchQueue.main.async {
                self?.isScannerBusy = false
            }
        }
    }

    func startBackupProcess() {
        // [REDACTED_TODO_COMMENT]
        if let cardViewModel = userWalletModel as? CardViewModel,
           let input = cardViewModel.backupInput {
            Analytics.log(.noticeBackupYourWalletTapped)
            coordinator.openOnboardingModal(with: input)
        }
    }

    func openOrganizeTokens() {
        coordinator.openOrganizeTokens(for: userWalletModel)
    }

    // [REDACTED_TODO_COMMENT]
    func openManageTokens() {
        let shouldShowLegacyDerivationAlert = userWalletModel.config.warningEvents.contains(where: { $0 == .legacyDerivation })

        let settings = LegacyManageTokensSettings(
            supportedBlockchains: userWalletModel.config.supportedBlockchains,
            hdWalletsSupported: userWalletModel.config.hasFeature(.hdWallets),
            longHashesSupported: userWalletModel.config.hasFeature(.longHashes),
            derivationStyle: userWalletModel.config.derivationStyle,
            shouldShowLegacyDerivationAlert: shouldShowLegacyDerivationAlert,
            existingCurves: (userWalletModel as? CardViewModel)?.card.walletCurves ?? []
        )

        coordinator.openManageTokens(with: settings, userTokensManager: userWalletModel.userTokensManager)
    }

    private func setup() {
        updateBackupStatus()
        subscribeToTokenListUpdatesIfNeeded()
        bind()
    }

    private func bind() {
        userWalletModel.userTokensManager.derivationManager?
            .pendingDerivationsCount
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { [weak self] pendingDerivationsCount in
                self?.updateMissingDerivationNotification(for: pendingDerivationsCount)
            })
            .store(in: &bag)

        sectionsProvider.sectionsPublisher
            .map(convertToSections(_:))
            .assign(to: \.sections, on: self, ownership: .weak)
            .store(in: &bag)

        userWalletModel.updatePublisher
            .sink { [weak self] in
                self?.updateBackupStatus()
            }
            .store(in: &bag)

        userWalletNotificationManager.notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func subscribeToTokenListUpdatesIfNeeded() {
        if userWalletModel.userTokensManager.isInitialSyncPerformed {
            isLoadingTokenList = false
            return
        }

        var tokenSyncSubscription: AnyCancellable?
        tokenSyncSubscription = userWalletModel.userTokensManager.initialSyncPublisher
            .filter { $0 }
            .sink(receiveValue: { [weak self] _ in
                self?.isLoadingTokenList = false
                withExtendedLifetime(tokenSyncSubscription) {}
            })
    }

    private func convertToSections(_ sections: [TokenListSectionInfo]) -> [MultiWalletTokenItemsSection] {
        // [REDACTED_TODO_COMMENT]
        // Or need to replace `unowned` references to `TokenItemInfoProvider` with `weak` references
        // Will be done in [REDACTED_INFO]
        MultiWalletTokenItemsSectionFactory()
            .makeSections(from: sections, tapAction: tokenItemTapped(_:))
    }

    private func tokenItemTapped(_ walletModelId: WalletModelId) {
        guard let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id == walletModelId }) else {
            return
        }

        coordinator.openTokenDetails(for: walletModel, userWalletModel: userWalletModel)
    }

    private func updateMissingDerivationNotification(for pendingDerivationsCount: Int) {
        guard pendingDerivationsCount > 0 else {
            missingDerivationNotificationSettings = nil
            return
        }

        let factory = NotificationsFactory()
        missingDerivationNotificationSettings = factory.buildMissingDerivationNotificationSettings(for: pendingDerivationsCount)
    }

    private func updateBackupStatus() {
        guard userWalletModel.config.hasFeature(.backup) else {
            missingBackupNotificationSettings = nil
            return
        }

        let factory = NotificationsFactory()
        missingBackupNotificationSettings = factory.missingBackupNotificationSettings()
    }
}

extension MultiWalletMainContentViewModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId) {
        guard let notification = notificationInputs.first(where: { $0.id == id }) else {
            userWalletNotificationManager.dismissNotification(with: id)
            return
        }

        switch notification.settings.event {
        case let userWalletEvent as WarningEvent:
            handleUserWalletNotificationTap(event: userWalletEvent, id: id)
        default:
            break
        }
    }

    func didTapNotificationButton(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .generateAddresses:
            deriveEntriesWithoutDerivation()
        case .backupCard:
            startBackupProcess()
        default:
            return
        }
    }

    private func handleUserWalletNotificationTap(event: WarningEvent, id: NotificationViewId) {
        switch event {
        case .multiWalletSignedHashes:
            error = AlertBuilder.makeAlert(
                title: event.title,
                message: Localization.alertSignedHashesMessage,
                with: .withPrimaryCancelButton(
                    secondaryTitle: Localization.commonUnderstand,
                    secondaryAction: { [weak self] in
                        self?.userWalletNotificationManager.dismissNotification(with: id)
                    }
                )
            )
        default:
            assertionFailure("This event shouldn't have tap action on main screen. Event: \(event)")
        }
    }
}
