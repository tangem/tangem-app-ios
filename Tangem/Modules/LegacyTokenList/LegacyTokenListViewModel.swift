//
//  LegacyTokenListViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 09/02/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt
import BlockchainSdk
import TangemSdk

class LegacyTokenListViewModel: ObservableObject {
    // I can't use @Published here, because of swiftui redraw perfomance drop
    var enteredSearchText = CurrentValueSubject<String, Never>("")

    @Published var coinViewModels: [ManageTokensCoinViewModel] = []

    @Published var isSaving: Bool = false
    @Published var alert: AlertBinder?
    @Published var pendingAdd: [TokenItem] = []
    @Published var pendingRemove: [TokenItem] = []

    var shouldShowAlert: Bool {
        settings.shouldShowLegacyDerivationAlert
    }

    var isSaveDisabled: Bool {
        pendingAdd.isEmpty && pendingRemove.isEmpty
    }

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    private lazy var loader = setupListDataLoader()
    private let settings: LegacyManageTokensSettings
    private let userTokensManager: UserTokensManager
    private var bag = Set<AnyCancellable>()
    private unowned let coordinator: LegacyTokenListRoutable

    init(settings: LegacyManageTokensSettings, userTokensManager: UserTokensManager, coordinator: LegacyTokenListRoutable) {
        self.settings = settings
        self.userTokensManager = userTokensManager
        self.coordinator = coordinator

        bind()
    }

    func saveChanges() {
        isSaving = true

        userTokensManager.update(
            itemsToRemove: pendingRemove,
            itemsToAdd: pendingAdd
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isSaving = false

                switch result {
                case .success:
                    self?.tokenListDidSave()
                case .failure(let error):
                    if error.isUserCancelled {
                        return
                    }

                    self?.alert = error.alertBinder
                }
            }
        }
    }

    func tokenListDidSave() {
        Analytics.log(.manageTokensButtonSaveChanges)
        closeModule()
    }

    func onAppear() {
        Analytics.log(.manageTokensScreenOpened)
        loader.reset(enteredSearchText.value)
    }

    func onDisappear() {
        DispatchQueue.main.async {
            self.pendingAdd = []
            self.pendingRemove = []
            self.enteredSearchText.value = ""
        }
    }

    func fetch() {
        loader.fetch(enteredSearchText.value)
    }
}

// MARK: - Navigation

extension LegacyTokenListViewModel {
    func closeModule() {
        coordinator.closeModule()
    }

    func openAddCustom() {
        Analytics.log(.manageTokensButtonCustomToken)
        coordinator.openAddCustom(settings: settings, userTokensManager: userTokensManager)
    }
}

// MARK: - Private

private extension LegacyTokenListViewModel {
    func bind() {
        enteredSearchText
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] string in
                if !string.isEmpty {
                    Analytics.log(.manageTokensSearched)
                }

                self?.loader.fetch(string)
            }
            .store(in: &bag)
    }

    func setupListDataLoader() -> ListDataLoader {
        let supportedBlockchains = settings.supportedBlockchains
        let loader = ListDataLoader(supportedBlockchains: supportedBlockchains)

        loader.$items
            .map { [weak self] items -> [ManageTokensCoinViewModel] in
                items.compactMap { self?.mapToCoinViewModel(coinModel: $0) }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.coinViewModels, on: self, ownership: .weak)
            .store(in: &bag)

        return loader
    }

    func isAdded(_ tokenItem: TokenItem) -> Bool {
        return userTokensManager.contains(tokenItem)
    }

    func canRemove(_ tokenItem: TokenItem) -> Bool {
        return userTokensManager.canRemove(tokenItem)
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

    func onSelect(_ selected: Bool, _ tokenItem: TokenItem) {
        if selected {
            if tokenItem.hasLongHashes,
               !settings.longHashesSupported {
                displayAlertAndUpdateSelection(
                    for: tokenItem,
                    title: Localization.commonAttention,
                    message: Localization.alertManageTokensUnsupportedMessage(tokenItem.blockchain.displayName)
                )

                return
            }

            if !settings.existingCurves.contains(tokenItem.blockchain.curve) {
                displayAlertAndUpdateSelection(
                    for: tokenItem,
                    title: Localization.commonAttention,
                    message: Localization.alertManageTokensUnsupportedCurveMessage(tokenItem.blockchain.displayName)
                )

                return
            }
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

    func updateSelection(_ tokenItem: TokenItem) {
        for item in coinViewModels {
            for itemItem in item.items {
                if itemItem.tokenItem == tokenItem {
                    itemItem.updateSelection(with: bindSelection(tokenItem))
                }
            }
        }
    }

    func bindSelection(_ tokenItem: TokenItem) -> Binding<Bool> {
        let binding = Binding<Bool> { [weak self] in
            self?.isSelected(tokenItem) ?? false
        } set: { [weak self] isSelected in
            self?.showWarningDeleteAlertIfNeeded(isSelected: isSelected, tokenItem: tokenItem)
        }

        return binding
    }

    func bindCopy() -> Binding<Bool> {
        let binding = Binding<Bool> {
            false
        } set: { _ in
            Toast(view: SuccessToast(text: Localization.contractAddressCopiedMessage))
                .present(
                    layout: .bottom(padding: 80),
                    type: .temporary()
                )
        }

        return binding
    }

    func mapToCoinViewModel(coinModel: CoinModel) -> ManageTokensCoinViewModel {
        let currencyItems = coinModel.items.enumerated().map { index, item in
            ManageTokensCoinItemViewModel(
                tokenItem: item.tokenItem,
                isReadonly: false,
                isSelected: bindSelection(item.tokenItem),
                isCopied: bindCopy(),
                position: .init(with: index, total: coinModel.items.count)
            )
        }

        return ManageTokensCoinViewModel(with: coinModel, items: currencyItems)
    }

    func showWarningDeleteAlertIfNeeded(isSelected: Bool, tokenItem: TokenItem) {
        guard !isSelected, userTokensManager.contains(tokenItem) else {
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
                tokenItem.name,
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

    func sendAnalyticsOnChangeTokenState(tokenIsSelected: Bool, tokenItem: TokenItem) {
        Analytics.log(event: .manageTokensSwitcherChanged, params: [
            .state: Analytics.ParameterValue.toggleState(for: tokenIsSelected).rawValue,
            .token: tokenItem.currencySymbol,
        ])
    }

    // MARK: - Private Implementation

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
}
