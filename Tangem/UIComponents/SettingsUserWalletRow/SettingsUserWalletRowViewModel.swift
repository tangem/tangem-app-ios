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

final class SettingsUserWalletRowViewModel: ObservableObject, Identifiable {
    @Published var name: String = ""
    @Published var icon: LoadingResult<ImageValue, Never> = .loading
    @Published var cardSetLabel: String
    @Published var isUserWalletBackupNeeded: Bool
    @Published var balanceState: LoadableTokenBalanceView.State = .loading()
    let tapAction: () -> Void

    let isUserWalletLocked: Bool
    private let userWalletUpdatePublisher: AnyPublisher<UpdateResult, Never>
    private let totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>
    private var walletImageProvider: WalletImageProviding
    private var bag: Set<AnyCancellable> = []

    convenience init(userWallet: UserWalletModel, tapAction: @escaping () -> Void) {
        self.init(
            name: userWallet.name,
            cardSetLabel: userWallet.config.cardSetLabel,
            isUserWalletBackupNeeded: userWallet.config.hasFeature(.mnemonicBackup) && userWallet.config.hasFeature(.iCloudBackup),
            isUserWalletLocked: userWallet.isUserWalletLocked,
            userWalletUpdatePublisher: userWallet.updatePublisher,
            totalBalancePublisher: userWallet.totalBalancePublisher,
            walletImageProvider: userWallet.walletImageProvider,
            tapAction: tapAction
        )
    }

    init(
        name: String,
        cardSetLabel: String,
        isUserWalletBackupNeeded: Bool,
        isUserWalletLocked: Bool,
        userWalletUpdatePublisher: AnyPublisher<UpdateResult, Never>,
        totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>,
        walletImageProvider: WalletImageProviding,
        tapAction: @escaping () -> Void
    ) {
        self.name = name
        self.cardSetLabel = cardSetLabel
        self.isUserWalletBackupNeeded = isUserWalletBackupNeeded
        self.isUserWalletLocked = isUserWalletLocked
        self.userWalletUpdatePublisher = userWalletUpdatePublisher
        self.totalBalancePublisher = totalBalancePublisher
        self.walletImageProvider = walletImageProvider
        self.tapAction = tapAction
        bind()
    }

    func loadImage() {
        guard icon.value == nil else {
            return
        }

        reloadImage()
    }

    func reloadImage() {
        runTask(in: self) { viewModel in
            let image = await viewModel.walletImageProvider.loadSmallImage()

            await runOnMain {
                viewModel.icon = .success(image)
            }
        }
    }

    func bind() {
        userWalletUpdatePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, event in
                switch event {
                case .nameDidChange(let name):
                    viewModel.name = name
                case .configurationChanged(let model):
                    viewModel.cardSetLabel = model.config.cardSetLabel
                    if case .configurationChanged(let model) = event {
                        let isUserWalletBackupNeeded = model.config.hasFeature(.mnemonicBackup) && model.config.hasFeature(.iCloudBackup)
                        viewModel.isUserWalletBackupNeeded = isUserWalletBackupNeeded
                        viewModel.walletImageProvider = model.walletImageProvider
                        viewModel.reloadImage()
                    }
                case .paeraCustomerCreated:
                    break
                }
            }
            .store(in: &bag)

        totalBalancePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { $0.setupBalanceState(state: $1) }
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
