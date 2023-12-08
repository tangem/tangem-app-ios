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
    private unowned let coordinator: ManageTokensNetworkSelectorRoutable

    /// CoinId from parent data source embedded on selected UserWalletModel
    private let parentEmbeddedCoinId: String?
    private let dataSource: ManageTokensNetworkDataSource

    private let coinId: String
    private let tokenItems: [TokenItem]

    private var selectedUserWalletModel: UserWalletModel? {
        dataSource.selectedUserWalletModel
    }

    private var isTokenAvailableForSwitching: Bool {
        selectedUserWalletModel != nil
    }

    // MARK: - Init

    init(
        parentDataSource: ManageTokensDataSource,
        coinId: String,
        tokenItems: [TokenItem],
        coordinator: ManageTokensNetworkSelectorRoutable
    ) {
        self.coinId = coinId
        self.tokenItems = tokenItems
        self.coordinator = coordinator
        parentEmbeddedCoinId = parentDataSource.defaultUserWalletModel?.embeddedCoinId

        dataSource = ManageTokensNetworkDataSource(parentDataSource)

        bind()
        setup()

        reloadSelectorItemsFromTokenItems()
    }

    // MARK: - Implementation

    func selectWalletActionDidTap() {
        Analytics.log(event: .manageTokensButtonChooseWallet, params: [:])
        coordinator.openWalletSelector(with: dataSource)
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
        dataSource.selectedUserWalletModelPublisher
            .sink { [weak self] userWalletId in
                guard let userWalletModel = self?.dataSource.userWalletModels.first(where: { $0.userWalletId == userWalletId }) else {
                    return
                }

                self?.setNeedSelectWallet(userWalletModel)
            }
            .store(in: &bag)
    }

    private func reloadSelectorItemsFromTokenItems() {
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
                    isAvailable: isTokenAvailableForSwitching
                )
            }

        nonNativeSelectorItems = tokenItems
            .filter {
                !$0.isBlockchain
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
                    isAvailable: isTokenAvailableForSwitching
                )
            }
    }

    /// This method that shows a configure notification input result if the condition is single currency by coinId
    private func setup() {
        guard dataSource.userWalletModels.isEmpty else {
            return
        }

        if parentEmbeddedCoinId != coinId {
            displayWarningNotification(for: .supportedOnlySingleCurrencyWallet)
        }
    }

    private func saveChanges() {
        guard let userTokensManager = dataSource.selectedUserWalletModel?.userTokensManager else {
            return
        }

        userTokensManager.update(
            itemsToRemove: pendingRemove,
            itemsToAdd: pendingAdd,
            derivationPath: nil
        )
    }

    private func isAvailableTokenSelection() -> Bool {
        !dataSource.userWalletModels.isEmpty
    }

    private func onSelect(_ selected: Bool, _ tokenItem: TokenItem) throws {
        guard let userTokensManager = dataSource.selectedUserWalletModel?.userTokensManager else {
            return
        }

        if selected {
            try userTokensManager.addTokenItemPrecondition(tokenItem)
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

    private func setNeedSelectWallet(_ userWalletModel: UserWalletModel?) {
        if selectedUserWalletModel?.userWalletId != userWalletModel?.userWalletId {
            Analytics.log(
                event: .manageTokensWalletSelected,
                params: [.source: Analytics.ParameterValue.mainToken.rawValue]
            )
        }

        pendingAdd = []
        pendingRemove = []

        currentWalletName = userWalletModel?.config.cardName ?? ""

        reloadSelectorItemsFromTokenItems()
    }
}

// MARK: - Helpers

private extension ManageTokensNetworkSelectorViewModel {
    func isTokenAvailable(_ tokenItem: TokenItem) -> Bool {
        guard let userTokensManager = dataSource.selectedUserWalletModel?.userTokensManager else {
            return false
        }

        do {
            try userTokensManager.addTokenItemPrecondition(tokenItem)
            return true
        } catch {
            return false
        }
    }

    func isAdded(_ tokenItem: TokenItem) -> Bool {
        if let userTokensManager = dataSource.selectedUserWalletModel?.userTokensManager {
            return userTokensManager.contains(tokenItem, derivationPath: nil)
        }

        return parentEmbeddedCoinId == tokenItem.blockchain.coinId
    }

    func canRemove(_ tokenItem: TokenItem) -> Bool {
        guard let userTokensManager = dataSource.selectedUserWalletModel?.userTokensManager else {
            return false
        }

        return userTokensManager.canRemove(tokenItem, derivationPath: nil)
    }

    func isSelected(_ tokenItem: TokenItem) -> Bool {
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
    func displayAlertAndUpdateSelection(for tokenItem: TokenItem, error: Error?) {
        let okButton = Alert.Button.default(Text(Localization.commonOk)) {
            self.updateSelection(tokenItem)
        }

        alert = AlertBinder(alert: Alert(
            title: Text(Localization.commonAttention),
            message: Text(error?.localizedDescription ?? ""),
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
                        displayAlertAndUpdateSelection(for: tokenItem, error: error as? LocalizedError)
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

private extension UserWalletModel {
    var embeddedCoinId: String? {
        config.embeddedBlockchain?.blockchainNetwork.blockchain.coinId
    }
}
