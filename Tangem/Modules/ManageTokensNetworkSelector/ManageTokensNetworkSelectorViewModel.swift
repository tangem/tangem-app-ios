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

final class ManageTokensNetworkSelectorViewModel: Identifiable, ObservableObject, WalletSelectorDelegate {
    // MARK: - Injected Properties

    @Injected(\.tokenQuotesRepository) private var tokenQuotesRepository: TokenQuotesRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Published Properties

    @Published var selectorItems: [ManageTokensNetworkSelectorItemViewModel] = []
    @Published var alert: AlertBinder?
    @Published var pendingAdd: [TokenItem] = []
    @Published var pendingRemove: [TokenItem] = []

    var isSaveDisabled: Bool {
        pendingAdd.isEmpty && pendingRemove.isEmpty
    }

    var walletSelectorViewModel: WalletSelectorViewModel? {
        guard let selectedModel = userWalletRepository.selectedModel else {
            return nil
        }

        let viewModel = WalletSelectorViewModel(
            userWallets: userWalletRepository.userWallets,
            currentUserWalletId: selectedModel.userWallet.userWalletId
        )

        viewModel.delegate = self
        return viewModel
    }

    // MARK: - Private Implementation

    private var tokenItems: [TokenItem]

    private var userTokensManager: UserTokensManager? {
        userWalletRepository.selectedModel?.userTokensManager
    }

    private var settings: Settings {
        let selectedModel = userWalletRepository.selectedModel

        return .init(
            supportedBlockchains: selectedModel?.config.supportedBlockchains ?? [],
            hdWalletsSupported: selectedModel?.userWallet.isHDWalletAllowed ?? false,
            longHashesSupported: selectedModel?.longHashesSupported ?? false,
            derivationStyle: nil,
            shouldShowLegacyDerivationAlert: selectedModel?.shouldShowLegacyDerivationAlert ?? false,
            existingCurves: selectedModel?.card.walletCurves ?? []
        )
    }

    // MARK: - Private Properties

    private unowned let coordinator: ManageTokensNetworkSelectorCoordinator

    // MARK: - Init

    init(tokenItems: [TokenItem], coordinator: ManageTokensNetworkSelectorCoordinator) {
        self.coordinator = coordinator
        self.tokenItems = tokenItems

        selectorItems = tokenItems.map {
            .init(
                id: $0.hashValue,
                isMain: $0.isBlockchain,
                iconName: $0.blockchain.iconName,
                iconNameSelected: $0.blockchain.iconNameFilled,
                networkName: $0.networkName,
                tokenTypeName: $0.name,
                isSelected: bindSelection($0)
            )
        }
    }

    // MARK: - Implementation

    func saveChanges() {
        guard let userTokensManager = userTokensManager else {
            return
        }

        userTokensManager.update(
            itemsToRemove: pendingRemove,
            itemsToAdd: pendingAdd,
            derivationPath: nil
        )

        tokenListDidSave()
    }

    // MARK: - Private Implementation

    private func tokenListDidSave() {
        Analytics.log(.buttonSaveChanges)
        coordinator.closeModule()
    }

    private func sendAnalyticsOnChangeTokenState(tokenIsSelected: Bool, tokenItem: TokenItem) {
        Analytics.log(event: .tokenSwitcherChanged, params: [
            .state: Analytics.ParameterValue.toggleState(for: tokenIsSelected).rawValue,
            .token: tokenItem.currencySymbol,
        ])
    }

    private func displayAlertAndUpdateSelection(for tokenItem: TokenItem, title: String, message: String) {
        let okButton = Alert.Button.default(Text(Localization.commonOk)) {
            self.updateSelection(tokenItem)
        }

        alert = AlertBinder(alert: Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: okButton
        ))
    }

    private func showWarningDeleteAlertIfNeeded(isSelected: Bool, tokenItem: TokenItem) {
        guard
            !isSelected,
            !pendingAdd.contains(tokenItem),
            isTokenAvailable(tokenItem)
        else {
            onSelect(isSelected, tokenItem)
            return
        }

        if canRemove(tokenItem) {
            let title = Localization.tokenDetailsHideAlertTitle(tokenItem.currencySymbol)

            let cancelAction = { [unowned self] in
                updateSelection(tokenItem)
            }

            let hideAction = { [unowned self] in
                onSelect(isSelected, tokenItem)
            }

            alert = AlertBinder(alert:
                Alert(
                    title: Text(title),
                    message: Text(Localization.tokenDetailsHideAlertMessage),
                    primaryButton: .destructive(Text(Localization.tokenDetailsHideAlertHide), action: hideAction),
                    secondaryButton: .cancel(cancelAction)
                )
            )
        } else {
            let title = Localization.tokenDetailsUnableHideAlertTitle(tokenItem.blockchain.currencySymbol)

            let message = Localization.tokenDetailsUnableHideAlertMessage(
                tokenItem.blockchain.currencySymbol,
                tokenItem.blockchain.displayName
            )

            alert = AlertBinder(alert: Alert(
                title: Text(title),
                message: Text(message),
                dismissButton: .default(Text(Localization.commonOk), action: {
                    self.updateSelection(tokenItem)
                })
            ))
        }
    }

    private func onSelect(_ selected: Bool, _ tokenItem: TokenItem) {
        if selected,
           case .token(_, let blockchain) = tokenItem,
           case .solana = blockchain,
           !settings.longHashesSupported {
            displayAlertAndUpdateSelection(
                for: tokenItem,
                title: Localization.commonAttention,
                message: Localization.alertManageTokensUnsupportedMessage
            )

            return
        }

        if selected, !settings.existingCurves.contains(tokenItem.blockchain.curve) {
            displayAlertAndUpdateSelection(
                for: tokenItem,
                title: Localization.commonAttention,
                message: Localization.alertManageTokensUnsupportedCurveMessage(tokenItem.blockchain.displayName)
            )

            return
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

    private func bindSelection(_ tokenItem: TokenItem) -> Binding<Bool> {
        let binding = Binding<Bool> { [weak self] in
            self?.isSelected(tokenItem) ?? false
        } set: { [weak self] isSelected in
            self?.showWarningDeleteAlertIfNeeded(isSelected: isSelected, tokenItem: tokenItem)
        }

        return binding
    }

    private func updateSelection(_ tokenItem: TokenItem) {
        selectorItems.first(where: { $0.id == tokenItem.hashValue })?.updateSelection(with: bindSelection(tokenItem))
    }

    private func isAdded(_ tokenItem: TokenItem) -> Bool {
        guard let userTokensManager = userTokensManager else { return false }
        return userTokensManager.contains(tokenItem, derivationPath: nil)
    }

    private func canRemove(_ tokenItem: TokenItem) -> Bool {
        guard let userTokensManager = userTokensManager else { return false }
        return userTokensManager.canRemove(tokenItem, derivationPath: nil)
    }

    private func isTokenAvailable(_ tokenItem: TokenItem) -> Bool {
        if case .token(_, let blockchain) = tokenItem,
           case .solana = blockchain,
           !settings.longHashesSupported {
            return false
        }

        if !settings.existingCurves.contains(tokenItem.blockchain.curve) {
            return false
        }

        return true
    }

    // MARK: - ManageTokensNetworkSelectorViewModel

    func didSelectWallet(with userWalletId: Data) {
        userWalletRepository.setSelectedUserWalletId(userWalletId, reason: .userSelected)
    }
}

extension ManageTokensNetworkSelectorViewModel {
    struct Settings {
        let supportedBlockchains: Set<Blockchain>
        let hdWalletsSupported: Bool
        let longHashesSupported: Bool
        let derivationStyle: DerivationStyle?
        let shouldShowLegacyDerivationAlert: Bool
        let existingCurves: [EllipticCurve]
    }
}
