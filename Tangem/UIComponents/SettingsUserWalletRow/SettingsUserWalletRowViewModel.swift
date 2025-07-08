//
//  SettingsUserWalletRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import TangemFoundation

class SettingsUserWalletRowViewModel: ObservableObject, Identifiable {
    @Published var name: String = ""
    @Published var icon: LoadingValue<ImageValue> = .loading
    @Published var cardsCount: String
    @Published var tokensCount: Int
    @Published var isUserWalletBackupNeeded: Bool = false
    @Published var balanceState: LoadableTokenBalanceView.State = .loading()
    let tapAction: () -> Void

    let isUserWalletLocked: Bool
    private let userWalletNamePublisher: AnyPublisher<String, Never>
    private let totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>
    private let isUserWalletBackupNeededPublisher: AnyPublisher<Bool, Never>
    private let walletImageProvider: WalletImageProviding
    private var bag: Set<AnyCancellable> = []

    convenience init(userWallet: UserWalletModel, tapAction: @escaping () -> Void) {
        self.init(
            cardsCount: userWallet.cardsCount,
            tokensCount: userWallet.userTokenListManager.userTokens.count,
            isUserWalletLocked: userWallet.isUserWalletLocked,
            userWalletNamePublisher: userWallet.userWalletNamePublisher,
            totalBalancePublisher: userWallet.totalBalancePublisher,
            isUserWalletBackupNeededPublisher: Empty().eraseToAnyPublisher(), // [REDACTED_TODO_COMMENT]
            walletImageProvider: userWallet.walletImageProvider,
            tapAction: tapAction
        )
    }

    init(
        cardsCount: Int,
        tokensCount: Int = 0,
        isUserWalletLocked: Bool,
        userWalletNamePublisher: AnyPublisher<String, Never>,
        totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>,
        isUserWalletBackupNeededPublisher: AnyPublisher<Bool, Never>,
        walletImageProvider: WalletImageProviding,
        tapAction: @escaping () -> Void
    ) {
        self.cardsCount = Localization.cardLabelCardCount(cardsCount)
        self.tokensCount = tokensCount
        self.isUserWalletLocked = isUserWalletLocked
        self.userWalletNamePublisher = userWalletNamePublisher
        self.totalBalancePublisher = totalBalancePublisher
        self.isUserWalletBackupNeededPublisher = isUserWalletBackupNeededPublisher
        self.walletImageProvider = walletImageProvider
        self.tapAction = tapAction
        bind()
    }

    func loadImage() {
        guard icon.value == nil else {
            return
        }

        runTask(in: self) { viewModel in
            let image = await viewModel.walletImageProvider.loadSmallImage()

            await runOnMain {
                viewModel.icon = .loaded(image)
            }
        }
    }

    func bind() {
        userWalletNamePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, name in
                viewModel.name = name
            }
            .store(in: &bag)

        totalBalancePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { $0.setupBalanceState(state: $1) }
            .store(in: &bag)

        isUserWalletBackupNeededPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, isBackupNeeded in
                viewModel.isUserWalletBackupNeeded = isBackupNeeded
            }
            .store(in: &bag)
    }

    func onAppear() {
        loadImage()
    }

    private func setupBalanceState(state: TotalBalanceState) {
        guard !isUserWalletLocked else {
            balanceState = .loaded(text: Localization.commonLocked)
            return
        }

        balanceState = LoadableTokenBalanceViewStateBuilder().buildTotalBalance(state: state)
    }
}
