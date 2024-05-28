//
//  OnboardingAddTokensViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt

class OnboardingAddTokensViewModel: ObservableObject {
    lazy var searchText: Binding<String> = Binding(
        get: { [weak self] in
            self?.adapter.enteredSearchText.value ?? ""
        },
        set: { [weak self] newValue in
            self?.adapter.enteredSearchText.send(newValue)
        }
    )

    let manageTokensListViewModel: ManageTokensListViewModel

    @Published var hasPendingChanges: Bool = false
    @Published var isSavingChanges: Bool = false

    var buttonSettings: MainButton.Settings {
        if hasPendingChanges {
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
            icon: .trailing(Assets.tangemIcon),
            style: .primary,
            size: .default,
            isLoading: isSavingChanges,
            action: weakify(self, forFunction: OnboardingAddTokensViewModel.saveChanges)
        )
    }

    private weak var delegate: OnboardingAddTokensDelegate?

    private let adapter: ManageTokensAdapter
    private var bag = Set<AnyCancellable>()

    init(adapter: ManageTokensAdapter, delegate: OnboardingAddTokensDelegate?) {
        self.adapter = adapter
        self.delegate = delegate
        manageTokensListViewModel = .init(loader: adapter, coinViewModelsPublisher: adapter.coinViewModelsPublisher)

        bind()
    }

    func saveChanges() {
        isSavingChanges = true

        adapter.saveChanges { [weak self] result in
            self?.isSavingChanges = false
            switch result {
            case .success:
                self?.delegate?.goToNextStep()
            case .failure(let failure):
                self?.delegate?.showAlert(failure.alertBinder)
            }
        }
    }

    func skipAddTokens() {
        delegate?.goToNextStep()
    }

    private func bind() {
        adapter.isPendingListsEmptyPublisher
            .assign(to: \.hasPendingChanges, on: self, ownership: .weak)
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
    }
}
