//
//  ManageTokensNetworkSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk
import TangemSdk

final class ManageTokensNetworkSelectorViewModel: Identifiable, ObservableObject {
    // MARK: - Published Properties

    @Published var currentWalletName: String = ""
    @Published var notificationInput: NotificationViewInput?

    @Published var nativeSelectorItems: [ManageTokensNetworkSelectorItemViewModel] = []
    @Published var nonNativeSelectorItems: [ManageTokensNetworkSelectorItemViewModel] = []

    @Published var alert: AlertBinder?
    @Published var pendingAdd: [TokenItem] = []
    @Published var pendingRemove: [TokenItem] = []

    var isSaveDisabled: Bool {
        pendingAdd.isEmpty && pendingRemove.isEmpty
    }

    // MARK: - Private Implementation

    private var bag = Set<AnyCancellable>()
    private let alertBuilder = ManageTokensNetworkSelectorAlertBuilder()
    private let networkDataSource: ManageTokensNetworkDataSource
    private unowned let coordinator: ManageTokensNetworkSelectorCoordinator

    private let coinModel: CoinModel

    private var selectedUserWalletModel: UserWalletModel? {
        networkDataSource.selectedUserWalletModelPublisher.value
    }

    private var settings: ManageTokensSettings? {
        guard let userWalletModel = selectedUserWalletModel else {
            return nil
        }

        var supportedBlockchains = userWalletModel.config.supportedBlockchains
        supportedBlockchains.remove(.ducatus)
        let shouldShowLegacyDerivationAlert = userWalletModel.config.warningEvents.contains(where: { $0 == .legacyDerivation })

        let settings = ManageTokensSettings(
            supportedBlockchains: supportedBlockchains,
            hdWalletsSupported: userWalletModel.config.hasFeature(.hdWallets),
            longHashesSupported: userWalletModel.config.hasFeature(.longHashes),
            derivationStyle: userWalletModel.config.derivationStyle,
            shouldShowLegacyDerivationAlert: shouldShowLegacyDerivationAlert,
            existingCurves: userWalletModel.config.walletCurves,
            isAvailableTokenSelection: true
        )

        return settings
    }

    private var userTokensManager: UserTokensManager? {
        selectedUserWalletModel?.userTokensManager
    }

    // MARK: - Init

    init(
        coinModel: CoinModel,
        coordinator: ManageTokensNetworkSelectorCoordinator
    ) {
        self.coinModel = coinModel
        self.coordinator = coordinator
        networkDataSource = ManageTokensNetworkDataSource(coinId: coinModel.id)

        bind()

        // Need use after binding for selectedUserWalletModelPublisher property
        networkDataSource.prepare()
    }

    // MARK: - Implementation

    func onAppear() {
        fillSelectorItemsFromTokenItems()
    }

    func selectWalletActionDidTap() {
        Analytics.log(event: .manageTokensButtonChooseWallet, params: [:])
        coordinator.openWalletSelector(with: networkDataSource)
    }

    func displayNonNativeNetworkAlert() {
        let okButton = Alert.Button.default(Text(Localization.commonOk)) {}

        alert = AlertBinder(alert: Alert(
            title: Text(""),
            message: Text(Localization.manageTokensNetworkSelectorNonNativeInfo),
            dismissButton: okButton
        ))
    }

    // MARK: - Private Implementation

    private func bind() {
        networkDataSource.selectedUserWalletModelPublisher
            .sink { [weak self] userWalletModel in
                self?.didSelect(userWalletModel)
            }
            .store(in: &bag)
    }

    private func setNeedDisplayNotifications() {
        notificationInput = nil

        guard networkDataSource.userWalletModels.isEmpty else {
            return
        }

        // Do not display flow notifications if use only single currency wallets supported current coinId
        if networkDataSource.isExistSingleCurrencyWalletSupportedCoinId() {
            return
        }

        if networkDataSource.isExistSingleCurrencyWalletDoesNotSupportedCoinId() {
            // Display flow notifications if use only single currency wallets does not supported current coinId
            displayWarningNotification(for: .supportedOnlySingleCurrencyWallet)

            return
        }

        // Display flow notifications if list of wallets does not supported current coinId
        displayWarningNotification(for: .walletsNotSupportedBlockchain)
    }

    private func fillSelectorItemsFromTokenItems() {
        let tokenItems = coinModel.items.map { $0.tokenItem }

        nativeSelectorItems = tokenItems
            .filter {
                $0.isBlockchain
            }
            .map {
                .init(
                    id: $0.hashValue,
                    isMain: $0.isBlockchain,
                    iconName: $0.blockchain.iconName,
                    iconNameSelected: $0.blockchain.iconNameFilled,
                    networkName: $0.networkName,
                    tokenTypeName: nil,
                    isSelected: bindSelection($0),
                    isAvailable: settings?.isAvailableTokenSelection ?? false
                )
            }

        nonNativeSelectorItems = tokenItems
            .filter {
                $0.isToken
            }
            .map {
                .init(
                    id: $0.hashValue,
                    isMain: $0.isBlockchain,
                    iconName: $0.blockchain.iconName,
                    iconNameSelected: $0.blockchain.iconNameFilled,
                    networkName: $0.networkName,
                    tokenTypeName: $0.blockchain.tokenTypeName,
                    isSelected: bindSelection($0),
                    isAvailable: settings?.isAvailableTokenSelection ?? false
                )
            }
    }

    private func saveChanges() {
        guard let userTokensManager = userTokensManager else {
            return
        }

        userTokensManager.update(
            itemsToRemove: pendingRemove,
            itemsToAdd: pendingAdd,
            derivationPath: nil
        )
    }

    private func onSelect(_ selected: Bool, _ tokenItem: TokenItem) throws {
        if selected {
            try tryTokenAvailable(tokenItem)
        }

        sendAnalyticsOnChangeTokenState(tokenIsSelected: selected, tokenItem: tokenItem)

        let alreadyAdded = isAdded(tokenItem)

        if alreadyAdded {
            if selected {
                pendingRemove.remove(tokenItem)
            } else {
                pendingRemove.append(tokenItem)
            }
        } else {
            if selected {
                pendingAdd.append(tokenItem)
            } else {
                pendingAdd.remove(tokenItem)
            }
        }

        saveChanges()
    }

    private func bindSelection(_ tokenItem: TokenItem) -> Binding<Bool> {
        let binding = Binding<Bool> { [weak self] in
            self?.isSelected(tokenItem) ?? false
        } set: { [weak self] isSelected in
            do {
                try self?.displayAlertWarningDeleteIfNeeded(isSelected: isSelected, tokenItem: tokenItem)
            } catch {
                self?.displayAlertAndUpdateSelection(for: tokenItem, error: error)
            }
        }

        return binding
    }

    private func updateSelection(_ tokenItem: TokenItem) {
        if tokenItem.isBlockchain {
            nativeSelectorItems
                .first(where: { $0.id == tokenItem.hashValue })?
                .updateSelection(with: bindSelection(tokenItem))
        } else {
            nonNativeSelectorItems
                .first(where: { $0.id == tokenItem.hashValue })?
                .updateSelection(with: bindSelection(tokenItem))
        }
    }

    private func sendAnalyticsOnChangeTokenState(tokenIsSelected: Bool, tokenItem: TokenItem) {
        Analytics.log(event: .manageTokensSwitcherChanged, params: [
            .state: Analytics.ParameterValue.toggleState(for: tokenIsSelected).rawValue,
            .token: tokenItem.currencySymbol,
        ])
    }

    private func didSelect(_ userWalletModel: UserWalletModel?) {
        if selectedUserWalletModel?.userWalletId != userWalletModel?.userWalletId {
            Analytics.log(
                event: .manageTokensWalletSelected,
                params: [.source: Analytics.ParameterValue.mainToken.rawValue]
            )
        }

        pendingAdd = []
        pendingRemove = []

        currentWalletName = userWalletModel?.config.cardName ?? ""

        fillSelectorItemsFromTokenItems()
        setNeedDisplayNotifications()
    }
}

// MARK: - Helpers

private extension ManageTokensNetworkSelectorViewModel {
    func tryTokenAvailable(_ tokenItem: TokenItem) throws {
        guard let settings = settings else {
            return
        }

        guard settings.supportedBlockchains.contains(tokenItem.blockchain) else {
            throw AvailableTokenError.failedSupportedBlockchainByCard
        }

        guard settings.existingCurves.contains(tokenItem.blockchain.curve) else {
            throw AvailableTokenError.failedSupportedCurve(tokenItem)
        }

        if settings.longHashesSupported, !tokenItem.blockchain.hasLongTransactions {
            throw AvailableTokenError.failedSupportedLongHahesTokens(blockchainDisplayName: tokenItem.blockchain.displayName)
        }

        return
    }

    func isTokenAvailable(_ tokenItem: TokenItem) -> Bool {
        return (try? tryTokenAvailable(tokenItem)) != nil
    }

    private func isAdded(_ tokenItem: TokenItem) -> Bool {
        userTokensManager?.contains(tokenItem, derivationPath: nil) ?? false
    }

    private func canRemove(_ tokenItem: TokenItem) -> Bool {
        userTokensManager?.canRemove(tokenItem, derivationPath: nil) ?? false
    }

    private func isSelected(_ tokenItem: TokenItem) -> Bool {
        let isWaitingToBeAdded = pendingAdd.contains(tokenItem)
        let isWaitingToBeRemoved = pendingRemove.contains(tokenItem)
        let alreadyAdded = isAdded(tokenItem)

        if isWaitingToBeRemoved {
            return false
        }

        return isWaitingToBeAdded || alreadyAdded
    }
}

// MARK: - Alerts

private extension ManageTokensNetworkSelectorViewModel {
    func displayAlertAndUpdateSelection(for tokenItem: TokenItem, error: Error) {
        guard let availableTokenError = error as? AvailableTokenError else {
            return
        }

        let okButton = Alert.Button.default(Text(Localization.commonOk)) {
            self.updateSelection(tokenItem)
        }

        alert = AlertBinder(alert: Alert(
            title: Text(availableTokenError.title),
            message: Text(availableTokenError.errorDescription ?? ""),
            dismissButton: okButton
        ))
    }

    func displayAlertAndUpdateSelection(for tokenItem: TokenItem, title: String, message: String) {
        let okButton = Alert.Button.default(Text(Localization.commonOk)) {
            self.updateSelection(tokenItem)
        }

        alert = AlertBinder(alert: Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: okButton
        ))
    }

    func displayAlertWarningDeleteIfNeeded(isSelected: Bool, tokenItem: TokenItem) throws {
        guard
            !isSelected,
            !pendingAdd.contains(tokenItem),
            isTokenAvailable(tokenItem)
        else {
            try onSelect(isSelected, tokenItem)
            return
        }

        if canRemove(tokenItem) {
            alert = alertBuilder.successCanRemoveAlertDeleteTokenIfNeeded(
                tokenItem: tokenItem,
                cancelAction: { [unowned self] in
                    updateSelection(tokenItem)
                },
                hideAction: { [unowned self] in
                    do {
                        try onSelect(isSelected, tokenItem)
                    } catch {
                        displayAlertAndUpdateSelection(for: tokenItem, error: error)
                    }
                }
            )
        } else {
            alert = alertBuilder.errorCanRemoveAlertDeleteTokenIfNeeded(
                tokenItem: tokenItem,
                dissmisAction: { [unowned self] item in
                    updateSelection(item)
                }
            )
        }
    }

    func displayWarningNotification(for event: WarningEvent) {
        let notificationsFactory = NotificationsFactory()

        notificationInput = notificationsFactory.buildNotificationInput(
            for: event,
            action: { _ in },
            buttonAction: { _, _ in },
            dismissAction: { _ in }
        )
    }
}

// MARK: - Errors

private extension ManageTokensNetworkSelectorViewModel {
    enum AvailableTokenError: Error, LocalizedError {
        case failedSupportedLongHahesTokens(blockchainDisplayName: String)
        case failedSupportedCurve(TokenItem)
        case failedSupportedBlockchainByCard

        var errorDescription: String? {
            switch self {
            case .failedSupportedLongHahesTokens(let blockchainDisplayName):
                return Localization.alertManageTokensUnsupportedMessage(blockchainDisplayName)
            case .failedSupportedCurve(let tokenItem):
                return Localization.alertManageTokensUnsupportedCurveMessage(tokenItem.blockchain.displayName)
            case .failedSupportedBlockchainByCard:
                return Localization.manageTokensWalletDoesNotSupportedBlockchain
            }
        }

        var title: String {
            return Localization.commonAttention
        }
    }
}
