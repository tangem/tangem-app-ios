//
//  SingleWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemUI
import struct TangemUIUtils.ConfirmationDialogViewModel

final class SingleWalletMainContentViewModel: SingleTokenBaseViewModel, ObservableObject {
    // MARK: - ViewState

    @Published var notificationInputs: [NotificationViewInput] = []
    @Published var notificationBannerItems: [NotificationBannerItem] = []
    @Published var walletPromoBannerViewModel: WalletPromoBannerViewModel?
    /// [REDACTED_INFO]: Remove when the redesign feature toggle is removed
    @Published var exploreConfirmationDialog: ConfirmationDialogViewModel?

    private(set) lazy var bottomSheetFooterViewModel = MainBottomSheetFooterViewModel()

    // MARK: - Redesign

    /// [REDACTED_INFO]: This should be unwrapped from container once redesign toggle is deleted
    private(set) var redesignState: RedesignState?

    var actionButtonsViewModel: ActionButtonsViewModel? {
        redesignState?.actionButtonsViewModel
    }

    // MARK: - Dependencies

    private let userWalletNotificationManager: NotificationManager
    private let rateAppController: RateAppInteractionController
    private let contextActionTokenRouter: SingleTokenRoutable

    private let isPageSelectedSubject = PassthroughSubject<Bool, Never>()

    private var bag: Set<AnyCancellable> = []

    private weak var delegate: SingleWalletMainContentDelegate?

    init(
        userWalletModel: UserWalletModel,
        walletModel: any WalletModel,
        userWalletNotificationManager: NotificationManager,
        pendingExpressTransactionsManager: PendingExpressTransactionsManager,
        tokenNotificationManager: NotificationManager,
        rateAppController: RateAppInteractionController,
        tokenRouter: SingleTokenRoutable,
        delegate: SingleWalletMainContentDelegate?,
        coordinator: (any ActionButtonsRoutable & MultiWalletMainContentRoutable)?,
        accountModel: (any CryptoAccountModel)?
    ) {
        self.userWalletNotificationManager = userWalletNotificationManager
        self.rateAppController = rateAppController
        contextActionTokenRouter = tokenRouter
        self.delegate = delegate

        if WalletPromoBannerUtil().shouldShowBanner() {
            walletPromoBannerViewModel = .init(
                currencySymbol: walletModel.tokenItem.currencySymbol,
                tokenRouter: tokenRouter
            )
        }

        super.init(
            userWalletInfo: userWalletModel.userWalletInfo,
            walletModel: walletModel,
            notificationManager: tokenNotificationManager,
            pendingExpressTransactionsManager: pendingExpressTransactionsManager,
            tokenRouter: tokenRouter
        )

        if FeatureProvider.isAvailable(.redesign) {
            setupRedesign(
                walletModel: walletModel,
                userWalletModel: userWalletModel,
                coordinator: coordinator,
                accountModel: accountModel
            )
        }

        bind()
    }

    private func setupRedesign(
        walletModel: any WalletModel,
        userWalletModel: UserWalletModel,
        coordinator: (any ActionButtonsRoutable & MultiWalletMainContentRoutable)?,
        accountModel: (any CryptoAccountModel)?
    ) {
        let infoProvider = DefaultTokenItemInfoProvider(walletModel: walletModel)

        let tokenIcon = TokenIconInfoBuilder().build(
            from: walletModel.tokenItem,
            isCustom: walletModel.isCustom
        )

        let tokenItemViewModel = TokenItemViewModel(
            id: walletModel.id,
            tokenItem: walletModel.tokenItem,
            tokenIcon: tokenIcon,
            infoProvider: infoProvider,
            contextActionsProvider: self,
            contextActionsDelegate: self,
            tokenTapped: { [weak coordinator, weak userWalletModel] _ in
                guard let coordinator, let userWalletModel else { return }
                coordinator.openTokenDetails(for: walletModel, userWalletModel: userWalletModel)
            },
            yieldApyTapped: nil
        )

        let actionButtonsVM: ActionButtonsViewModel? = coordinator.map {
            ActionButtonsViewModel(
                coordinator: $0,
                expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletId: userWalletModel.userWalletId),
                userWalletModel: userWalletModel
            )
        }

        let tokenCardVariant: RedesignState.TokenCardVariant
        if let accountModel {
            @Injected(\.expandableAccountItemStateStorageProvider)
            var stateStorageProvider: ExpandableAccountItemStateStorageProvider

            let stateStorage = stateStorageProvider.makeStateStorage(for: userWalletModel.userWalletId)

            let expandableAccountViewModel = ExpandableAccountItemViewModel(
                accountModel: accountModel,
                stateStorage: stateStorage,
                onManageTokensTap: {
                    // This route is only available if we have empty tokens list, which cannot happen on single-wallet cards
                    assertionFailure("Single token is always displayed, this route shouldn't happen")
                }
            )
            tokenCardVariant = .account(expandableAccountViewModel, tokenItemViewModel)
        } else {
            tokenCardVariant = .token(tokenItemViewModel)
        }

        redesignState = RedesignState(
            actionButtonsViewModel: actionButtonsVM,
            tokenCardVariant: tokenCardVariant,
            tokenItemInfoProvider: infoProvider
        )
    }

    /// [REDACTED_INFO]: Remove when the redesign feature toggle is removed
    override func present(exploreConfirmationDialog: ConfirmationDialogViewModel) {
        self.exploreConfirmationDialog = exploreConfirmationDialog
    }

    override func copyDefaultAddress() {
        super.copyDefaultAddress()
        Analytics.log(
            event: .buttonCopyAddress,
            params: [
                .token: walletModel.tokenItem.currencySymbol,
                .source: Analytics.ParameterValue.main.rawValue,
            ],
            analyticsSystems: .all
        )
        delegate?.displayAddressCopiedToast()
    }

    override func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .openFeedbackMail:
            rateAppController.openFeedbackMail()
        case .openAppStoreReview:
            rateAppController.openAppStoreReview()
        default:
            super.didTapNotification(with: id, action: action)
        }
    }

    /// [REDACTED_INFO]: Remove when the redesign feature toggle is removed
    override func openMarketsTokenDetails() {
        guard isMarketsDetailsAvailable else {
            return
        }

        let analyticsParams: [Analytics.ParameterKey: String] = [
            .source: Analytics.ParameterValue.main.rawValue,
            .token: walletModel.tokenItem.currencySymbol.uppercased(),
            .blockchain: walletModel.tokenItem.blockchain.displayName,
        ]
        Analytics.log(event: .marketsChartScreenOpened, params: analyticsParams)
        super.openMarketsTokenDetails()
    }

    private func bind() {
        userWalletNotificationManager
            .notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        let mapper = MultiWalletNotificationBannerMapper()

        $notificationInputs
            .combineLatest($tokenNotificationInputs)
            .map { mapper.mapItems($0, $1) }
            .removeDuplicates()
            .assign(to: &$notificationBannerItems)

        rateAppController.bind(
            isPageSelectedPublisher: isPageSelectedSubject,
            notificationsPublisher: $notificationInputs
        )
    }
}

// MARK: - MainViewPage protocol conformance

extension SingleWalletMainContentViewModel: MainViewPage {
    func onPageAppear() {
        isPageSelectedSubject.send(true)
    }

    func onPageDisappear() {
        isPageSelectedSubject.send(false)
    }
}

// MARK: - TokenItemContextActionsProvider

extension SingleWalletMainContentViewModel: TokenItemContextActionsProvider {
    func buildContextActions(for tokenItemViewModel: TokenItemViewModel) -> [TokenContextActionsSection] {
        let actionBuilder = TokenContextActionsSectionBuilder()
        return actionBuilder.buildContextActionsSections(
            tokenItem: tokenItemViewModel.tokenItem,
            walletModel: walletModel,
            userWalletConfig: userWalletInfo.config,
            canNavigateToMarketsDetails: isMarketsDetailsAvailable,
            canHideToken: false
        )
    }
}

// MARK: - TokenItemContextActionDelegate

extension SingleWalletMainContentViewModel: TokenItemContextActionDelegate {
    func didTapContextAction(_ action: TokenActionType, for tokenItemViewModel: TokenItemViewModel) {
        switch action {
        case .buy:
            contextActionTokenRouter.openOnramp(walletModel: walletModel)
        case .send:
            contextActionTokenRouter.openSend(walletModel: walletModel)
        case .receive:
            contextActionTokenRouter.openReceive(walletModel: walletModel)
        case .exchange:
            contextActionTokenRouter.openSwap(walletModel: walletModel)
        case .sell:
            contextActionTokenRouter.openSell(for: walletModel)
        case .stake:
            contextActionTokenRouter.openStaking(walletModel: walletModel)
        case .yield:
            contextActionTokenRouter.openYieldModule(walletModel: walletModel)
        case .copyAddress:
            copyDefaultAddress()
        case .marketsDetails:
            openMarketsTokenDetails()
        case .hide:
            break
        }
    }
}

// MARK: - RedesignState

extension SingleWalletMainContentViewModel {
    struct RedesignState {
        let actionButtonsViewModel: ActionButtonsViewModel?
        let tokenCardVariant: TokenCardVariant

        /// Retained because `TokenItemViewModel.infoProvider` is weak
        let tokenItemInfoProvider: DefaultTokenItemInfoProvider

        enum TokenCardVariant {
            /// Plain token row (no account header)
            case token(TokenItemViewModel)
            /// Token row wrapped in an expandable account card
            case account(ExpandableAccountItemViewModel, TokenItemViewModel)
        }
    }
}
