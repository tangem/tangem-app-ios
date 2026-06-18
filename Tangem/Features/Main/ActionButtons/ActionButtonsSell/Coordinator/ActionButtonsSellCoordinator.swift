//
//  ActionButtonsSellCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

final class ActionButtonsSellCoordinator: CoordinatorObject {
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.sellService) private var sellService: SellService

    @Published private(set) var viewState: RootViewState?

    let dismissAction: Action<ActionButtonsSendToSellModel?>
    let popToRootAction: Action<PopToRootOptions>

    private var safariHandle: SafariHandle?

    private let userWalletModel: UserWalletModel

    required init(
        dismissAction: @escaping Action<ActionButtonsSendToSellModel?>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in },
        userWalletModel: some UserWalletModel
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
        self.userWalletModel = userWalletModel
    }

    func start(with options: Options) {
        viewState = .tokenList(
            ActionButtonsSellViewModel(
                tokenSelectorViewModel: options.tokenSelectorViewModel,
                coordinator: self
            )
        )
    }
}

// MARK: - Options / RootViewState

extension ActionButtonsSellCoordinator {
    struct Options {
        let tokenSelectorViewModel: TokenSelectorViewModel
    }

    enum RootViewState: Equatable {
        case tokenList(ActionButtonsSellViewModel)
        case transfer(TransferViewModel)
        case send(SendCoordinator)
        case swap(SendCoordinator)

        static func == (lhs: RootViewState, rhs: RootViewState) -> Bool {
            switch (lhs, rhs) {
            case (.tokenList, .tokenList): true
            case (.transfer, .transfer): true
            case (.send, .send): true
            case (.swap, .swap): true
            default: false
            }
        }
    }
}

// MARK: - ActionButtonsSellRoutable

extension ActionButtonsSellCoordinator: ActionButtonsSellRoutable {
    func openSellCrypto(
        at url: URL,
        makeSellToSendToModel: @escaping (String) -> ActionButtonsSendToSellModel?
    ) {
        safariHandle = safariManager.openURL(url) { [weak self] closeURL in
            let sendToSellModel = makeSellToSendToModel(closeURL.absoluteString)

            self?.safariHandle = nil
            self?.dismiss(with: sendToSellModel)
        }
    }

    func openTransfer(walletModel: any WalletModel, userWalletInfo: UserWalletInfo) {
        viewState = .transfer(
            TransferViewModel(
                walletModel: walletModel,
                userWalletInfo: userWalletInfo,
                coordinator: self
            )
        )
    }

    func dismiss() {
        dismiss(with: nil)
    }
}

// MARK: - TransferRoutable

extension ActionButtonsSellCoordinator: TransferRoutable {
    func transferRequestSell(walletModel: any WalletModel, userWalletInfo: UserWalletInfo) {
        guard let url = makeSellUrl(walletModel: walletModel) else {
            return
        }

        openSellCrypto(at: url) { [weak self] response in
            self?.makeSendToSellModel(from: response, and: walletModel)
        }
    }

    func transferRequestSwap(walletModel: any WalletModel, userWalletInfo: UserWalletInfo) {
        let helper = SwapPredefinedParametersHelper()
        guard let parameters = helper.makeParameters(
            walletModel: walletModel,
            userWalletInfo: userWalletInfo,
            position: .from
        ) else {
            return
        }

        let sendCoordinator = SendCoordinator(dismissAction: { [weak self] _ in self?.dismiss() })
        sendCoordinator.start(with: .init(type: .swap(parameters), source: .actionButtons))
        viewState = .swap(sendCoordinator)
    }

    func transferRequestSend(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo
    ) {
        let sourceToken = CommonSendSwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            operationType: .swapAndSend
        ).makeSwapableToken()

        let sendCoordinator = SendCoordinator(dismissAction: { [weak self] _ in self?.dismiss() })
        sendCoordinator.start(with: .init(type: .send(sourceToken), source: .actionButtons))
        viewState = .send(sendCoordinator)
    }

    func transferRequestSwapAndSend(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo
    ) {
        let sourceToken = CommonSendSwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            operationType: .swapAndSend
        ).makeSwapableToken()

        let sendCoordinator = SendCoordinator(dismissAction: { [weak self] _ in self?.dismiss() })
        sendCoordinator.start(
            with: .init(
                type: .send(sourceToken),
                source: .actionButtons,
                shouldStartFromTokenList: true
            ))
        viewState = .send(sendCoordinator)
    }

    func transferClose() {
        dismiss()
    }
}

// MARK: - Sell URL

private extension ActionButtonsSellCoordinator {
    func makeSellUrl(walletModel: any WalletModel) -> URL? {
        sellService.getSellUrl(
            currencySymbol: walletModel.tokenItem.currencySymbol,
            amountType: walletModel.tokenItem.amountType,
            blockchain: walletModel.tokenItem.blockchain,
            walletAddress: walletModel.defaultAddressString
        )
    }

    func makeSendToSellModel(from response: String, and walletModel: any WalletModel) -> ActionButtonsSendToSellModel? {
        let sellUtility = SellCryptoUtility(
            tokenItem: walletModel.tokenItem,
            address: walletModel.defaultAddressString
        )

        guard let sellCryptoRequest = sellUtility.extractSellCryptoRequest(from: response) else {
            return nil
        }

        let sellParameters = PredefinedSellParameters(
            amount: sellCryptoRequest.amount,
            destination: sellCryptoRequest.targetAddress,
            tag: sellCryptoRequest.tag
        )

        return .init(sellParameters: sellParameters, walletModel: walletModel)
    }
}
