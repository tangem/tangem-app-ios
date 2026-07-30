//
//  OnboardingAddTokensViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import SwiftUI
import Combine
import CombineExt
import TangemAssets
import TangemUI
import BlockchainSdk
import TangemSdk

class OnboardingAddTokensViewModel: ObservableObject {
    @Published private(set) var manageTokensListViewModel: ManageTokensListViewModel?

    // We need to use @Published here, because our CustomSearchField doesn't work properly
    // with bindings created from CurrentValueSubject
    @Published var searchText: String = ""
    @Published var isPendingListsEmpty: Bool = false
    @Published var isSavingChanges: Bool = false
    @Published var needsCardDerivation: Bool = false

    var buttonSettings: MainButton.Settings {
        if isPendingListsEmpty {
            return .init(
                title: Localization.commonLater,
                style: .secondary,
                size: .default,
                isLoading: false,
                action: weakify(self, forFunction: OnboardingAddTokensViewModel.saveChanges)
            )
        }

        return .init(
            title: Localization.commonContinue,
            icon: needsCardDerivation ? .trailing(Assets.tangemIcon) : nil,
            style: .primary,
            size: .default,
            isLoading: isSavingChanges,
            action: weakify(self, forFunction: OnboardingAddTokensViewModel.saveChanges)
        )
    }

    private weak var delegate: OnboardingAddTokensDelegate?

    private var adapter: ManageTokensAdapter?
    private var bag = Set<AnyCancellable>()

    init(input: Input, delegate: OnboardingAddTokensDelegate?) {
        self.delegate = delegate
        bindMainAccount(input: input)
    }

    func saveChanges() {
        guard let adapter else {
            delegate?.goToNextStep()
            return
        }

        isSavingChanges = true

        if isPendingListsEmpty {
            Analytics.log(.manageTokensButtonLater)
        }

        adapter.saveChanges { [weak self] result in
            self?.isSavingChanges = false
            switch result {
            case .success:
                self?.delegate?.goToNextStep()
            case .failure(let failure):
                if failure.isCancellationError {
                    return
                }

                self?.delegate?.showAlert(failure.alertBinder)
            }
        }
    }

    func skipAddTokens() {
        delegate?.goToNextStep()
    }

    private func bindMainAccount(input: Input) {
        input.accountModelsManager
            .cryptoAccountModelsPublisher
            .compactMap { $0.first(where: { $0.isMainAccount }) }
            .first()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, mainAccount in
                let context = CommonManageTokensContext(
                    accountModelsManager: input.accountModelsManager,
                    currentAccount: mainAccount
                )

                let adapter = ManageTokensAdapter(
                    settings: .init(
                        existingCurves: input.existingCurves,
                        supportedBlockchains: input.supportedBlockchains,
                        hardwareLimitationUtil: input.hardwareLimitationUtil,
                        analyticsSourceRawValue: input.analyticsSourceRawValue,
                        context: context
                    )
                )

                viewModel.setup(adapter: adapter)
            }
            .store(in: &bag)
    }

    private func setup(adapter: ManageTokensAdapter) {
        self.adapter = adapter
        manageTokensListViewModel = .init(loader: self, listItemsViewModelsPublisher: adapter.listItemsViewModelsPublisher)

        bind(adapter: adapter)
    }

    private func bind(adapter: ManageTokensAdapter) {
        adapter.isPendingListsEmptyPublisher
            .assign(to: \.isPendingListsEmpty, on: self, ownership: .weak)
            .store(in: &bag)

        adapter.alertPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, alert in
                guard let alert else {
                    return
                }

                viewModel.delegate?.showAlert(alert)
            }
            .store(in: &bag)

        adapter
            .needsCardDerivationPublisher
            .receiveOnMain()
            .assign(to: &$needsCardDerivation)

        $searchText
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, searchText in
                if !searchText.isEmpty {
                    Analytics.log(.manageTokensSearched)
                }

                viewModel.adapter?.fetch(searchText)
            }
            .store(in: &bag)
    }
}

extension OnboardingAddTokensViewModel: ManageTokensListLoader {
    var hasNextPage: Bool {
        adapter?.hasNextPage ?? false
    }

    func fetch() {
        adapter?.fetch(searchText)
    }
}

// MARK: - Input

extension OnboardingAddTokensViewModel {
    struct Input {
        let accountModelsManager: AccountModelsManager
        let existingCurves: [EllipticCurve]
        let supportedBlockchains: Set<Blockchain>
        let hardwareLimitationUtil: HardwareLimitationsUtil
        let analyticsSourceRawValue: String
    }
}
