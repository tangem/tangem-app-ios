//
//  OnrampViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress

class OnrampViewModel: ObservableObject, Identifiable {
    @Published private(set) var onrampAmountViewModel: OnrampAmountViewModel
    @Published private(set) var onrampProvidersCompactViewModel: OnrampProvidersCompactViewModel

    @Published private(set) var notificationInputs: [NotificationViewInput] = []
    @Published private(set) var notificationButtonIsLoading = false
    @Published private(set) var legalText: AttributedString?

    weak var router: OnrampSummaryRoutable?

    private let interactor: OnrampInteractor
    private let notificationManager: NotificationManager
    private var bag: Set<AnyCancellable> = []

    init(
        onrampAmountViewModel: OnrampAmountViewModel,
        onrampProvidersCompactViewModel: OnrampProvidersCompactViewModel,
        notificationManager: NotificationManager,
        interactor: OnrampInteractor
    ) {
        self.onrampAmountViewModel = onrampAmountViewModel
        self.onrampProvidersCompactViewModel = onrampProvidersCompactViewModel
        self.notificationManager = notificationManager
        self.interactor = interactor

        bind()
    }

    func openOnrampSettingsView() {
        router?.openOnrampSettingsView()
    }
}

// MARK: - Private

private extension OnrampViewModel {
    func bind() {
        notificationManager
            .notificationPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        interactor
            .isLoadingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.notificationButtonIsLoading, on: self, ownership: .weak)
            .store(in: &bag)

        interactor
            .selectedLoadedProviderPublisher
            .removeDuplicates()
            .map { $0?.legalText(branch: .onramp) }
            .receive(on: DispatchQueue.main)
            .assign(to: \.legalText, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

// MARK: - SendStepViewAnimatable

extension OnrampViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}
