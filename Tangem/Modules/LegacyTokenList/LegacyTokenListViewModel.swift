//
//  LegacyTokenListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt

class LegacyTokenListViewModel: ObservableObject {
    var enteredSearchText: Binding<String> {
        Binding(
            get: { [weak self] in
                self?.adapter.enteredSearchText.value ?? ""
            },
            set: { [weak self] in
                self?.adapter.enteredSearchText.send($0)
            }
        )
    }

    var manageTokensListViewModel: ManageTokensListViewModel!

    @Published var coinViewModels: [LegacyCoinViewModel] = []

    @Published var isSaving: Bool = false
    @Published var alert: AlertBinder?
    @Published var isSaveButtonDisabled = true

    let shouldShowLegacyDerivationAlert: Bool

    private let adapter: ManageTokensAdapter

    private let settings: LegacyManageTokensSettings
    private let userTokensManager: UserTokensManager
    private var bag = Set<AnyCancellable>()
    private unowned let coordinator: LegacyTokenListRoutable

    init(settings: LegacyManageTokensSettings, userTokensManager: UserTokensManager, coordinator: LegacyTokenListRoutable) {
        self.settings = settings
        self.userTokensManager = userTokensManager
        self.coordinator = coordinator

        shouldShowLegacyDerivationAlert = settings.shouldShowLegacyDerivationAlert
        adapter = .init(
            longHashesSupported: settings.longHashesSupported,
            existingCurves: settings.existingCurves,
            supportedBlockchains: settings.supportedBlockchains,
            userTokensManager: userTokensManager
        )

        manageTokensListViewModel = .init(
            loader: self,
            coinViewModelsPublisher: $coinViewModels
        )

        bind()
    }

    func saveChanges() {
        isSaving = true

        adapter.saveChanges { [weak self] result in
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
        adapter.fetch()
    }

    func onDisappear() {
        adapter.resetAdapter()
    }
}

extension LegacyTokenListViewModel: ManageTokensListLoader {
    var hasNextPage: Bool {
        adapter.hasNextPage
    }

    func fetch() {
        adapter.fetch()
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
        adapter.alertPublisher
            .assign(to: \.alert, on: self, ownership: .weak)
            .store(in: &bag)

        adapter.coinViewModelsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.coinViewModels, on: self, ownership: .weak)
            .store(in: &bag)

        adapter.isPendingListsEmptyPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSaveButtonDisabled, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
