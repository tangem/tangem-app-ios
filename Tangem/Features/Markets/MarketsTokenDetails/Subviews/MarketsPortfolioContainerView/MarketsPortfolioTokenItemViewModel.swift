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

final class MarketsPortfolioTokenItemViewModel: ObservableObject, Identifiable {
    // MARK: - Public Properties

    @Published var balanceCrypto: LoadableTokenBalanceView.State = .loading()
    @Published var balanceFiat: LoadableTokenBalanceView.State = .loading()
    @Published var contextActions: [TokenActionType] = []

    @Published var hasPendingTransactions: Bool = false

    @Published private var missingDerivation: Bool = false
    @Published private var networkUnreachable: Bool = false

    @Injected(\.storyAvailabilityService) private var storyAvailabilityService: any StoryAvailabilityService

    var name: String { tokenIcon.name }
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
    let walletName: String
    let tokenIcon: TokenIconInfo
    let tokenItem: TokenItem

    // MARK: - Private Properties

    private weak var tokenItemInfoProvider: TokenItemInfoProvider?
    private weak var balanceRestrictionFeatureAvailabilityProvider: BalanceRestrictionFeatureAvailabilityProvider?
    private weak var contextActionsProvider: MarketsPortfolioContextActionsProvider?
    private weak var contextActionsDelegate: MarketsPortfolioContextActionsDelegate?

    private let isSwapActionAvailableSubject = CurrentValueSubject<Bool, Never>(false)

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        walletModelId: WalletModelId,
        userWalletId: UserWalletId,
        walletName: String,
        tokenIcon: TokenIconInfo,
        tokenItem: TokenItem,
        tokenItemInfoProvider: TokenItemInfoProvider,
        balanceRestrictionFeatureAvailabilityProvider: BalanceRestrictionFeatureAvailabilityProvider,
        contextActionsProvider: MarketsPortfolioContextActionsProvider,
        contextActionsDelegate: MarketsPortfolioContextActionsDelegate
    ) {
        self.walletModelId = walletModelId
        self.userWalletId = userWalletId
        self.walletName = walletName
        self.tokenIcon = tokenIcon
        self.tokenItem = tokenItem
        self.tokenItemInfoProvider = tokenItemInfoProvider
        self.balanceRestrictionFeatureAvailabilityProvider = balanceRestrictionFeatureAvailabilityProvider
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
            .combineLatest(isSwapActionAvailableSubject)
            .receiveOnGlobal()
            .compactMap { [weak self] _, isActionButtonsAvailable in
                self?.contextActions(isActionButtonsAvailable: isActionButtonsAvailable)
            }
            .receiveOnMain()
            .assign(to: &$contextActions)

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

        balanceRestrictionFeatureAvailabilityProvider?.isActionButtonsAvailablePublisher
            .removeDuplicates()
            .subscribe(isSwapActionAvailableSubject)
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
        balanceCrypto = LoadableTokenBalanceViewStateBuilder().build(type: type)
    }

    private func setupFiatBalance(_ type: FormattedTokenBalanceType) {
        balanceFiat = LoadableTokenBalanceViewStateBuilder().build(type: type, icon: .leading)
    }

    private func contextActions(isActionButtonsAvailable: Bool) -> [TokenActionType] {
        var contextActions = contextActionsProvider?.buildContextActions(
            tokenItem: tokenItem,
            walletModelId: walletModelId,
            userWalletId: userWalletId
        ) ?? []

        if !isActionButtonsAvailable {
            contextActions.removeAll { $0 == .exchange }
        }

        return contextActions
    }
}
