//
//  TokenItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BlockchainSdk
import TangemFoundation

protocol TokenItemContextActionsProvider: AnyObject {
    func buildContextActions(for tokenItemViewModel: TokenItemViewModel) -> [TokenContextActionsSection]
}

protocol TokenItemContextActionDelegate: AnyObject {
    func didTapContextAction(_ action: TokenActionType, for tokenItemViewModel: TokenItemViewModel)
}

final class TokenItemViewModel: ObservableObject, Identifiable {
    let id: WalletModelId

    @Published var balanceCrypto: LoadableTokenBalanceView.State
    @Published var balanceFiat: LoadableTokenBalanceView.State
    @Published var priceChangeState: TokenPriceChangeView.State = .loading
    @Published var tokenPrice: LoadableTextView.State = .loading
    @Published var hasPendingTransactions: Bool = false
    @Published var contextActionSections: [TokenContextActionsSection] = []
    @Published var isStaked: Bool = false

    @Published private var missingDerivation: Bool = false
    @Published private var networkUnreachable: Bool = false

    let tokenItem: TokenItem

    var name: String { tokenIcon.name }
    var imageURL: URL? { tokenIcon.imageURL }
    var blockchainIconName: String? { tokenIcon.blockchainIconName }
    var hasMonochromeIcon: Bool { networkUnreachable || missingDerivation || tokenItem.blockchain.isTestnet }
    var isCustom: Bool { tokenIcon.isCustom }
    var customTokenColor: Color? { tokenIcon.customTokenColor }

    var hasError: Bool { missingDerivation || networkUnreachable }
    var errorMessage: String? {
        // Don't forget to add check in trailing item in `TokenItemView` when adding new error here
        if missingDerivation {
            return Localization.commonNoAddress
        }

        if networkUnreachable {
            return Localization.commonUnreachable
        }

        return nil
    }

    private let tokenIcon: TokenIconInfo
    private let priceChangeUtility = PriceChangeUtility()
    private let loadableTokenBalanceViewStateBuilder: LoadableTokenBalanceViewStateBuilder
    private let priceFormatter = TokenItemPriceFormatter()
    private var bag = Set<AnyCancellable>()

    private weak var infoProvider: TokenItemInfoProvider?
    private weak var contextActionsProvider: TokenItemContextActionsProvider?
    private weak var contextActionsDelegate: TokenItemContextActionDelegate?

    private let tokenTapped: (WalletModelId) -> Void

    init(
        id: WalletModelId,
        tokenItem: TokenItem,
        tokenIcon: TokenIconInfo,
        infoProvider: TokenItemInfoProvider,
        contextActionsProvider: TokenItemContextActionsProvider,
        contextActionsDelegate: TokenItemContextActionDelegate,
        tokenTapped: @escaping (WalletModelId) -> Void
    ) {
        self.id = id
        self.tokenIcon = tokenIcon
        self.tokenItem = tokenItem
        self.infoProvider = infoProvider
        self.contextActionsProvider = contextActionsProvider
        self.contextActionsDelegate = contextActionsDelegate
        self.tokenTapped = tokenTapped

        loadableTokenBalanceViewStateBuilder = .init()
        balanceCrypto = loadableTokenBalanceViewStateBuilder.build(type: infoProvider.balanceType)
        balanceFiat = loadableTokenBalanceViewStateBuilder.build(type: infoProvider.fiatBalanceType)

        setupView(infoProvider.balance)
        setupPrice(infoProvider.quote)
        bind()
    }

    deinit {
        AppLog.shared.debug("deinit \(self)")
    }

    func tapAction() {
        tokenTapped(id)
    }

    func didTapContextAction(_ actionType: TokenActionType) {
        contextActionsDelegate?.didTapContextAction(actionType, for: self)
    }

    private func bind() {
        infoProvider?.balancePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] type in
                self?.setupView(type)
            })
            .store(in: &bag)

        infoProvider?
            .balanceTypePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] type in
                self?.setupBalance(type)
            })
            .store(in: &bag)

        infoProvider?
            .fiatBalanceTypePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] type in
                self?.setupFiatBalance(type)
            })
            .store(in: &bag)

        infoProvider?
            .quotePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] type in
                self?.setupPrice(type)
            })
            .store(in: &bag)

        infoProvider?.actionsUpdatePublisher
            .receive(on: DispatchQueue.global())
            .withWeakCaptureOf(self)
            .map { $0.0.contextActionsProvider?.buildContextActions(for: $0.0) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] actions in
                self?.contextActionSections = actions ?? []
            }
            .store(in: &bag)

        infoProvider?.isStakedPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isStaked, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func setupView(_ type: TokenBalanceType) {
        switch type {
        case .empty(.noDerivation):
            missingDerivation = true
        default:
            missingDerivation = false
        }

        updatePendingTransactionsStateIfNeeded()
    }

    private func setupBalance(_ type: FormattedTokenBalanceType) {
        balanceCrypto = loadableTokenBalanceViewStateBuilder.build(type: type)
    }

    private func setupFiatBalance(_ type: FormattedTokenBalanceType) {
        balanceFiat = loadableTokenBalanceViewStateBuilder.build(type: type, icon: .leading)
    }

    private func setupPrice(_ quote: TokenQuote?) {
        guard let quote else {
            tokenPrice = .noData
            priceChangeState = .empty
            return
        }

        priceChangeState = priceChangeUtility.convertToPriceChangeState(changePercent: quote.priceChange24h)

        let priceText = priceFormatter.formatPrice(quote.price)
        tokenPrice = .loaded(text: priceText)
    }

    private func updatePendingTransactionsStateIfNeeded() {
        hasPendingTransactions = infoProvider?.hasPendingTransactions ?? false
    }

    private func buildContextActions() {
        contextActionSections = contextActionsProvider?.buildContextActions(for: self) ?? []
    }
}

// MARK: - CustomStringConvertible

extension TokenItemViewModel: CustomStringConvertible {
    var description: String {
        TangemFoundation.objectDescription(self, userInfo: ["id": id])
    }
}
