//
//  MarketsPortfolioTokenItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import SwiftUI
import TangemAssets
import TangemStories
import TangemFoundation
import struct TangemUI.TokenIconInfo
import TangemUI

final class MarketsPortfolioTokenItemViewModel: ObservableObject, Identifiable {
    // MARK: - Public Properties

    @Published var balanceCrypto: LoadableBalanceView.State = .loading()
    @Published var balanceFiat: LoadableBalanceView.State = .loading()
    @Published var contextActions: [TokenActionType] = []

    @Published var hasPendingTransactions: Bool = false

    @Published private var missingDerivation: Bool = false
    @Published private var networkUnreachable: Bool = false

    @Injected(\.storyAvailabilityService) private var storyAvailabilityService: any StoryAvailabilityService

    var tokenIconName: String { tokenIcon.name }
    var imageURL: URL? { tokenIcon.imageURL }
    var blockchainIconAsset: ImageType? { tokenIcon.blockchainIconAsset }
    var hasMonochromeIcon: Bool { networkUnreachable || missingDerivation }
    var isCustom: Bool { tokenIcon.isCustom }
    var customTokenColor: Color? { tokenIcon.customTokenColor }
    var hasError: Bool { missingDerivation || networkUnreachable }
    var hasZeroBalance: Bool { tokenItemInfoProvider?.balance.value ?? 0 == 0 }

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

    let walletModelId: WalletModelId
    let userWalletId: UserWalletId
    let name: String
    let description: String
    let tokenIcon: TokenIconInfo
    let tokenItem: TokenItem

    // MARK: - Private Properties

    private weak var tokenItemInfoProvider: TokenItemInfoProvider?
    private weak var contextActionsProvider: MarketsPortfolioContextActionsProvider?
    private weak var contextActionsDelegate: MarketsPortfolioContextActionsDelegate?

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        walletModelId: WalletModelId,
        userWalletId: UserWalletId,
        name: String,
        description: String,
        tokenIcon: TokenIconInfo,
        tokenItem: TokenItem,
        tokenItemInfoProvider: TokenItemInfoProvider,
        contextActionsProvider: MarketsPortfolioContextActionsProvider,
        contextActionsDelegate: MarketsPortfolioContextActionsDelegate
    ) {
        self.walletModelId = walletModelId
        self.userWalletId = userWalletId
        self.name = name
        self.description = description
        self.tokenIcon = tokenIcon
        self.tokenItem = tokenItem
        self.tokenItemInfoProvider = tokenItemInfoProvider
        self.contextActionsProvider = contextActionsProvider
        self.contextActionsDelegate = contextActionsDelegate

        bind()
        setupView(tokenItemInfoProvider.balance)
    }

    func showContextActions() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        contextActionsDelegate?.showContextAction(for: self)
    }

    func didTapContextAction(_ actionType: TokenActionType) {
        contextActionsDelegate?.didTapContextAction(actionType, walletModelId: walletModelId, userWalletId: userWalletId)
    }

    func shouldShowUnreadNotificationBadge(for actionType: TokenActionType) -> Bool {
        switch actionType {
        case .exchange:
            storyAvailabilityService.checkStoryAvailability(storyId: .swap)
        default:
            false
        }
    }

    // MARK: - Private Implementation

    private func bind() {
        tokenItemInfoProvider?
            .balancePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] type in
                self?.setupView(type)
            })
            .store(in: &bag)

        tokenItemInfoProvider?
            .balanceTypePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] type in
                self?.setupBalance(type)
            })
            .store(in: &bag)

        tokenItemInfoProvider?
            .fiatBalanceTypePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] type in
                self?.setupFiatBalance(type)
            })
            .store(in: &bag)

        tokenItemInfoProvider?
            .actionsUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.buildContextActions()
            }
            .store(in: &bag)

        storyAvailabilityService
            .availableStoriesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &bag)

        tokenItemInfoProvider?.hasPendingTransactions
            .receive(on: DispatchQueue.main)
            .assign(to: \.hasPendingTransactions, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func setupView(_ type: TokenBalanceType) {
        switch type {
        case .empty(.noDerivation):
            missingDerivation = true
        default:
            missingDerivation = false
        }

        buildContextActions()
    }

    private func setupBalance(_ type: FormattedTokenBalanceType) {
        balanceCrypto = LoadableBalanceViewStateBuilder().build(type: type)
    }

    private func setupFiatBalance(_ type: FormattedTokenBalanceType) {
        balanceFiat = LoadableBalanceViewStateBuilder().build(type: type, icon: .leading)
    }

    private func buildContextActions() {
        contextActions = contextActionsProvider?.buildContextActions(
            tokenItem: tokenItem,
            walletModelId: walletModelId,
            userWalletId: userWalletId
        ) ?? []
    }
}
