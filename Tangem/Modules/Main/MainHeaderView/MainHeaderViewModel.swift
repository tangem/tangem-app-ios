//
//  MainHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class MainHeaderViewModel: ObservableObject {
    let isUserWalletLocked: Bool

    @Published private(set) var userWalletName: String = ""
    @Published private(set) var subtitleInfo: MainHeaderSubtitleInfo = .empty
    @Published private(set) var balance: AttributedString = .init(BalanceFormatter.defaultEmptyBalanceString)
    @Published var isLoadingFiatBalance: Bool = true
    @Published var isLoadingSubtitle: Bool = true

    var subtitleContainsSensitiveInfo: Bool {
        subtitleProvider.containsSensitiveInfo
    }

    private weak var supplementInfoProvider: MainHeaderSupplementInfoProvider?
    private let subtitleProvider: MainHeaderSubtitleProvider
    private let balanceProvider: MainHeaderBalanceProvider

    private var bag: Set<AnyCancellable> = []

    init(
        isUserWalletLocked: Bool,
        supplementInfoProvider: MainHeaderSupplementInfoProvider,
        subtitleProvider: MainHeaderSubtitleProvider,
        balanceProvider: MainHeaderBalanceProvider
    ) {
        self.isUserWalletLocked = isUserWalletLocked

        self.supplementInfoProvider = supplementInfoProvider
        self.subtitleProvider = subtitleProvider
        self.balanceProvider = balanceProvider

        bind()
    }

    private func bind() {
        supplementInfoProvider?.userWalletNamePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.userWalletName, on: self, ownership: .weak)
            .store(in: &bag)

        subtitleProvider.isLoadingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoadingSubtitle, on: self, ownership: .weak)
            .store(in: &bag)

        subtitleProvider.subtitlePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.subtitleInfo, on: self, ownership: .weak)
            .store(in: &bag)

        balanceProvider.balanceProvider
            .receive(on: DispatchQueue.main)
            .debounce(for: 0.2, scheduler: DispatchQueue.main) // Hide skeleton and apply state with delay, mimic current behavior
            .sink { [weak self] newValue in
                guard let self else {
                    return
                }

                switch newValue {
                case .loading:
                    isLoadingFiatBalance = true
                case .loaded(let balance):
                    isLoadingFiatBalance = false

                    self.balance = balance
                case .failedToLoad(let error):
                    AppLog.shared.debug("Failed to load total balance. Reason: \(error)")
                    isLoadingFiatBalance = false

                    balance = .init(BalanceFormatter.defaultEmptyBalanceString)
                }
            }
            .store(in: &bag)
    }
}
