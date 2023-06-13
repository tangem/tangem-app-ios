//
//  TokenDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

enum ActionButtonType {
    case buy
    case send
    case receive
    case exchange
    case sell

    var title: String {
        switch self {
        case .buy: return Localization.commonBuy
        case .send: return Localization.commonSend
        case .receive: return Localization.commonReceive
        case .exchange: return Localization.commonExchange
        case .sell: return Localization.commonSell
        }
    }

    var icon: ImageType {
        switch self {
        case .buy: return Assets.plusMini
        case .send: return Assets.arrowUpMini
        case .receive: return Assets.arrowDownMini
        case .exchange: return Assets.exchangeMini
        case .sell: return Assets.dollarMini
        }
    }
}

final class TokenDetailsViewModel: ObservableObject {
    // MARK: - ViewState

    var balanceWithButtonsModel: BalanceWithButtonsViewModel!

    // MARK: - Dependencies

    private unowned let coordinator: TokenDetailsRoutable

    private let cardModel: CardViewModel
    private let walletModel: WalletModel
    private let blockchainNetwork: BlockchainNetwork
    private let amountType: Amount.AmountType

    @Published private var balance: LoadingValue<BalanceInfo> = .loading
    @Published private var actionButtons: [ButtonWithIconInfo] = []

    private var bag = Set<AnyCancellable>()

    init(
        cardModel: CardViewModel,
        walletModel: WalletModel,
        blockchainNetwork: BlockchainNetwork,
        amountType: Amount.AmountType,
        coordinator: TokenDetailsRoutable
    ) {
        self.coordinator = coordinator
        self.walletModel = walletModel
        self.cardModel = cardModel
        self.blockchainNetwork = blockchainNetwork
        self.amountType = amountType

        balanceWithButtonsModel = .init(balanceProvider: self, buttonsProvider: self)
    }

    func onRefresh(_ done: @escaping () -> Void) {}

    private func bind() {
        walletModel.$state
            .sink { completion in
                AppLog.shared.debug(completion)
            } receiveValue: { newState in
                AppLog.shared.debug("Wallet model new state: \(newState)")
            }
            .store(in: &bag)
    }

    private func updateBalance(walletModelState: WalletModel.State) {}

    private func updateActionButtons(walletModelState: WalletModel.State) {
        let receiveButton = ButtonWithIconInfo(
            buttonType: .receive,
            action: openReceiveSheet,
            disabled: false
        )

        var buttons: [ButtonWithIconInfo] = []
        buttons.append(receiveButton)
        actionButtons = buttons
    }
}

extension TokenDetailsViewModel {
    func openReceiveSheet() {}
}

extension TokenDetailsViewModel: BalanceProvider {
    var balancePublisher: AnyPublisher<LoadingValue<BalanceInfo>, Never> { $balance.eraseToAnyPublisher() }
}

extension TokenDetailsViewModel: ActionButtonsProvider {
    var buttonsPublisher: AnyPublisher<[ButtonWithIconInfo], Never> { $actionButtons.eraseToAnyPublisher() }
}
