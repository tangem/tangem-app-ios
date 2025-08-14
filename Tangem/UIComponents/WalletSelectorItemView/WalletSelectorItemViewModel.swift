//
//  WalletSelectorItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization

class WalletSelectorItemViewModel: ObservableObject, Identifiable {
    @Published var name: String = ""
    @Published var icon: LoadingValue<ImageValue> = .loading
    @Published var cardsCount: String
    @Published var balanceState: LoadableTokenBalanceView.State = .loading()
    @Published var isSelected: Bool = false

    let userWalletId: UserWalletId
    let isUserWalletLocked: Bool

    private let totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>
    private weak var infoProvider: WalletSelectorInfoProvider?

    private var onTapWallet: ((UserWalletId) -> Void)?

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(
        userWalletId: UserWalletId,
        cardsCount: Int,
        isUserWalletLocked: Bool,
        infoProvider: WalletSelectorInfoProvider,
        totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>,
        isSelected: Bool,
        didTapWallet: ((UserWalletId) -> Void)?
    ) {
        self.userWalletId = userWalletId
        self.isUserWalletLocked = isUserWalletLocked
        self.cardsCount = Localization.cardLabelCardCount(cardsCount)
        self.infoProvider = infoProvider
        name = infoProvider.name

        self.totalBalancePublisher = totalBalancePublisher

        self.isSelected = isSelected
        onTapWallet = didTapWallet

        bind()
        loadImage()
    }

    func loadImage() {
        runTask(in: self) { viewModel in
            guard let image = await viewModel.infoProvider?.walletImageProvider.loadSmallImage() else {
                return
            }

            await runOnMain {
                viewModel.icon = .loaded(image)
            }
        }
    }

    func bind() {
        infoProvider?
            .updatePublisher
            .compactMap(\.newName)
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
    }

    private func setupBalanceState(state: TotalBalanceState) {
        guard !isUserWalletLocked else {
            balanceState = .loaded(text: Localization.commonLocked)
            return
        }

        balanceState = LoadableTokenBalanceViewStateBuilder().buildTotalBalance(state: state)
    }

    func onTapAction() {
        onTapWallet?(userWalletId)
    }
}
