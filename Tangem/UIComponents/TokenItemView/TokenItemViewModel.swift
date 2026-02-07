//
//  TokenItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import SwiftUI
import BlockchainSdk
import TangemAssets
import TangemFoundation
import TangemStaking
import struct TangemUI.TokenIconInfo

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
    @Published var contextActionSections: [TokenContextActionsSection] = []
    @Published private var missingDerivation: Bool = false
    @Published private var networkUnreachable: Bool = false

    @Published var leadingBadge: LeadingBadge?
    @Published var trailingBadge: TrailingBadge?

    let tokenItem: TokenItem

    var name: String { tokenIcon.name }
    var imageURL: URL? { tokenIcon.imageURL }
    var blockchainIconAsset: ImageType? { tokenIcon.blockchainIconAsset }
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

    var yieldApyTapAction: (() -> Void)? {
        guard let action = yieldApyTapped else { return nil }
        return { [weak self] in
            guard let self else { return }
            action(tokenItem)
        }
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
    private let yieldApyTapped: ((TokenItem) -> Void)?

    init(
        id: WalletModelId,
        tokenItem: TokenItem,
        tokenIcon: TokenIconInfo,
        infoProvider: TokenItemInfoProvider,
        contextActionsProvider: TokenItemContextActionsProvider,
        contextActionsDelegate: TokenItemContextActionDelegate,
        tokenTapped: @escaping (WalletModelId) -> Void,
        yieldApyTapped: ((TokenItem) -> Void)?
    ) {
        self.id = id
        self.tokenIcon = tokenIcon
        self.tokenItem = tokenItem
        self.infoProvider = infoProvider
        self.contextActionsProvider = contextActionsProvider
        self.contextActionsDelegate = contextActionsDelegate
        self.tokenTapped = tokenTapped
        self.yieldApyTapped = yieldApyTapped

        loadableTokenBalanceViewStateBuilder = .init()
        balanceCrypto = loadableTokenBalanceViewStateBuilder.build(type: infoProvider.balanceType)
        balanceFiat = loadableTokenBalanceViewStateBuilder.build(type: infoProvider.fiatBalanceType)

        setupView(infoProvider.balance)
        setupPrice(infoProvider.quote)
        bind()
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

        infoProvider?.leadingBadgePublisher
            .receiveOnMain()
            .assign(to: \.leadingBadge, on: self, ownership: .weak)
            .store(in: &bag)

        infoProvider?.trailingBadgePublisher
            .receiveOnMain()
            .assign(to: \.trailingBadge, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func setupView(_ type: TokenBalanceType) {
        switch type {
        case .empty(.noDerivation):
            missingDerivation = true
        default:
            missingDerivation = false
        }
    }

    private func setupBalance(_ type: FormattedTokenBalanceType) {
        balanceCrypto = loadableTokenBalanceViewStateBuilder.build(type: type)
    }

    private func setupFiatBalance(_ type: FormattedTokenBalanceType) {
        balanceFiat = loadableTokenBalanceViewStateBuilder.build(type: type, icon: .leading)
    }

    private func setupPrice(_ rate: WalletModelRate) {
        switch rate {
        case .loading(.none):
            tokenPrice = .loading
            priceChangeState = .loading
        // If we have a cached rate we just show it
        // Exactly the loading animation will show on fiat balance
        case .loading(.some(let quote)), .failure(.some(let quote)), .loaded(let quote):
            tokenPrice = .loaded(text: priceFormatter.formatPrice(quote.price))
            priceChangeState = priceChangeUtility.convertToPriceChangeState(changePercent: quote.priceChange24h)
        case .custom, .failure(.none):
            tokenPrice = .noData
            priceChangeState = .empty
        }
    }

    private func buildContextActions() {
        contextActionSections = contextActionsProvider?.buildContextActions(for: self) ?? []
    }
}

// MARK: - CustomStringConvertible

extension TokenItemViewModel: CustomStringConvertible {
    var description: String {
        objectDescription(self, userInfo: ["id": id])
    }
}

extension TokenItemViewModel {
    enum LeadingBadge {
        case pendingTransaction
        case rewards(TokenItemViewModel.RewardsInfo)
    }

    enum TrailingBadge {
        case isApproveNeeded
    }
}

extension TokenItemViewModel {
    struct RewardsInfo: Equatable {
        let type: RewardType
        let rewardValue: String
        let isActive: Bool
        let isUpdating: Bool
    }
}
