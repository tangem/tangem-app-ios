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

    private let userWalletNamePublisher: AnyPublisher<String, Never>
    private let totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>
    private let cardImageProvider: CardImageProviding

    private var onTapWallet: ((UserWalletId) -> Void)?

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(
        userWalletId: UserWalletId,
        cardsCount: Int,
        isUserWalletLocked: Bool,
        userWalletNamePublisher: AnyPublisher<String, Never>,
        totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>,
        cardImageProvider: CardImageProviding,
        isSelected: Bool,
        didTapWallet: ((UserWalletId) -> Void)?
    ) {
        self.userWalletId = userWalletId
        self.isUserWalletLocked = isUserWalletLocked
        self.cardsCount = Localization.cardLabelCardCount(cardsCount)
        self.userWalletNamePublisher = userWalletNamePublisher
        self.totalBalancePublisher = totalBalancePublisher
        self.cardImageProvider = cardImageProvider
        self.isSelected = isSelected
        onTapWallet = didTapWallet

        bind()
        loadImage()
    }

    func loadImage() {
        TangemFoundation.runTask(in: self) { viewModel in
            let image = await viewModel.cardImageProvider.loadSmallImage()

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
