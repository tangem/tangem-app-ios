//
//  TokenDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemSdk
import BlockchainSdk
import TangemSwapping

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
    @Injected(\.keysManager) private var keysManager: KeysManager

    @Published var alert: AlertBinder? = nil

    @Published private var balance: LoadingValue<BalanceInfo> = .loading
    @Published private var actionButtons: [ButtonWithIconInfo] = []

    private(set) var balanceWithButtonsModel: BalanceWithButtonsViewModel!

    private unowned let coordinator: TokenDetailsRoutable
    private let swappingUtils = SwappingAvailableUtils()
    private let exchangeUtility: ExchangeCryptoUtility

    private let cardModel: CardViewModel
    private let walletModel: WalletModel
    private let blockchainNetwork: BlockchainNetwork
    private let amountType: Amount.AmountType

    private lazy var testnetBuyCryptoService: TestnetBuyCryptoService = .init()

    private var availableActions: [ActionButtonType] = []
    private var bag = Set<AnyCancellable>()

    private var canSend: Bool {
        guard cardModel.canSend else {
            return false
        }

        guard canSignLongTransactions else {
            return false
        }

        return walletModel.wallet.canSend(amountType: amountType)
    }

    private var canSignLongTransactions: Bool {
        if NFCUtils.isPoorNfcQualityDevice,
           case .solana = blockchain {
            return false
        } else {
            return true
        }
    }

    private var blockchain: Blockchain { blockchainNetwork.blockchain }

    private var currencySymbol: String {
        amountType.token?.symbol ?? blockchainNetwork.blockchain.currencySymbol
    }

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

        exchangeUtility = .init(blockchain: blockchainNetwork.blockchain, address: walletModel.wallet.address, amountType: amountType)
        balanceWithButtonsModel = .init(balanceProvider: self, buttonsProvider: self)

        prepareSelf()
    }

    func onRefresh(_ done: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            done()
        }
    }
}

// MARK: - Setup functions
private extension TokenDetailsViewModel {
    private func prepareSelf() {
        bind()
        setupActionButtons()
        loadSwappingState()
        updateActionButtons()
    }

    private func setupActionButtons() {
        let canExchange = cardModel.canExchangeCrypto
        let canBuy = exchangeUtility.buyAvailable
        let canSell = exchangeUtility.sellAvailable

        var availableActions: [ActionButtonType] = []
        availableActions.append(contentsOf: [.send, .receive])

        if canExchange {
            if canBuy {
                availableActions.insert(.buy, at: 0)
            }
            if canSell {
                availableActions.append(.sell)
            }
        }

        self.availableActions = availableActions
    }

    private func bind() {
        walletModel.$state
            .receive(on: DispatchQueue.main)
            .sink { completion in
                AppLog.shared.debug(completion)
            } receiveValue: { [weak self] newState in
                self?.updateBalance(walletModelState: newState)
                self?.updateActionButtons()
                AppLog.shared.debug("Wallet model new state: \(newState)")
            }
            .store(in: &bag)
    }

    private func updateBalance(walletModelState: WalletModel.State) {
        switch walletModelState {
        case .created, .loading:
            balance = .loading
        case .idle:
            balance = .loaded(.init(
                balance: walletModel.getDecimalBalance(for: amountType) ?? 0,
                currencyCode: currencySymbol
            ))
        case .noAccount(let message), .failed(let message):
            balance = .failedToLoad(error: message)
        case .noDerivation:
            balance = .failedToLoad(error: Localization.customTokenCustomDerivation)
        }
    }

    private func updateActionButtons() {
        let buttons = availableActions.map { type in
            let action = action(for: type)
            let isDisabled = isButtonDisabled(type: type)

            return ButtonWithIconInfo(buttonType: type, action: action, disabled: isDisabled)
        }

        actionButtons = buttons
    }

    private func loadSwappingState() {
        guard
            FeatureProvider.isAvailable(.exchange),
            cardModel.canShowSwapping,
            swappingUtils.isSwapAvailable(for: blockchain)
        else {
            return
        }

        var swappingSubscription: AnyCancellable?
        swappingSubscription = swappingUtils
            .canSwap(amount: amountType, blockchain: blockchain)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                swappingSubscription = nil
                AppLog.shared.debug("Load swapping availability state completion: \(completion)")
            } receiveValue: { [weak self] isSwapAvailable in
                if isSwapAvailable, let receiveIndex = self?.availableActions.firstIndex(of: .receive) {
                    self?.availableActions.insert(.exchange, at: receiveIndex + 1)
                    self?.updateActionButtons()
                }
            }
    }

    private func isButtonDisabled(type: ActionButtonType) -> Bool {
        guard case .send = type else {
            return false
        }

        return !canSend
    }

    private func action(for buttonType: ActionButtonType) -> () -> Void {
        switch buttonType {
        case .buy: return openBuy
        case .send: return openSend
        case .receive: return openReceive
        case .exchange: return openExchange
        case .sell: return openSell
        }
    }
}

// MARK: - Navigation functions

private extension TokenDetailsViewModel {
    func openBuy() {
        if let disabledLocalizedReason = cardModel.getDisabledLocalizedReason(for: .exchange) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        if let token = amountType.token, blockchain == .ethereum(testnet: true) {
            testnetBuyCryptoService.buyCrypto(.erc20Token(
                token,
                walletManager: walletModel.walletManager,
                signer: cardModel.signer
            ))
            return
        }

        guard let url = exchangeUtility.buyURL else { return }

        coordinator.openBuyCrypto(at: url, closeUrl: exchangeUtility.buyCryptoCloseURL) { [weak self] _ in
            guard let self else { return }
            Analytics.log(event: .tokenBought, params: [.token: currencySymbol])

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.walletModel.update(silent: true)
            }
        }
    }

    func openSend() {
        guard let amountToSend = walletModel.wallet.amounts[amountType] else { return }

        Analytics.log(.buttonSend)
        coordinator.openSend(
            amountToSend: amountToSend,
            blockchainNetwork: blockchainNetwork,
            cardViewModel: cardModel
        )
    }

    func openReceive() {}

    func openExchange() {
        if let disabledLocalizedReason = cardModel.getDisabledLocalizedReason(for: .swapping) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        let mapper = CurrencyMapper()

        let sourceCurrency: Currency?
        switch amountType {
        case .token(let token):
            sourceCurrency = mapper.mapToCurrency(token: token, blockchain: blockchain)
        default:
            sourceCurrency = mapper.mapToCurrency(blockchain: blockchain)
        }

        guard let source = sourceCurrency else { return }

        var referrer: SwappingReferrerAccount?

        if let account = keysManager.swapReferrerAccount {
            referrer = SwappingReferrerAccount(address: account.address, fee: account.fee)
        }

        let input = CommonSwappingModulesFactory.InputModel(
            userWalletModel: cardModel,
            walletModel: walletModel,
            sender: walletModel.walletManager,
            signer: cardModel.signer,
            logger: AppLog.shared,
            referrer: referrer,
            source: source
        )

        coordinator.openSwapping(input: input)
    }

    func openSell() {
        Analytics.log(.buttonSell)

        if let disabledLocalizedReason = cardModel.getDisabledLocalizedReason(for: .exchange) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        guard let url = exchangeUtility.sellURL else {
            return
        }

        coordinator.openSellCrypto(at: url, sellRequestUrl: exchangeUtility.sellCryptoCloseURL) { [weak self] response in
            if let request = self?.exchangeUtility.extractSellCryptoRequest(from: response) {
                self?.openSendToSell(with: request)
            }
        }
    }

    func openSendToSell(with request: SellCryptoRequest) {
        let amount = Amount(with: blockchainNetwork.blockchain, value: request.amount)
        coordinator.openSendToSell(
            amountToSend: amount,
            destination: request.targetAddress,
            blockchainNetwork: blockchainNetwork,
            cardViewModel: cardModel
        )
    }
}

extension TokenDetailsViewModel: BalanceProvider {
    var balancePublisher: AnyPublisher<LoadingValue<BalanceInfo>, Never> { $balance.eraseToAnyPublisher() }
}

extension TokenDetailsViewModel: ActionButtonsProvider {
    var buttonsPublisher: AnyPublisher<[ButtonWithIconInfo], Never> { $actionButtons.eraseToAnyPublisher() }
}
