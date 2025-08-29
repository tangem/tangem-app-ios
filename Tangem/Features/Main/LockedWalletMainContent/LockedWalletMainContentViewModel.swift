//
//  LockedWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

protocol MainLockedUserWalletDelegate: AnyObject {
    func openUnlockUserWalletBottomSheet(for userWalletModel: UserWalletModel)
}

class LockedWalletMainContentViewModel: ObservableObject {
    lazy var lockedNotificationInput: NotificationViewInput = {
        let factory = NotificationsFactory()
        let event: GeneralNotificationEvent = .walletLocked
        return .init(
            style: .tappable { [weak self] _ in
                self?.onLockedWalletNotificationTap()
            },
            severity: event.severity,
            settings: .init(event: event, dismissAction: nil)
        )
    }()

    lazy var singleWalletButtonsInfo: [FixedSizeButtonWithIconInfo] = TokenActionAvailabilityProvider.buildActionsForLockedSingleWallet()
        .map {
            FixedSizeButtonWithIconInfo(
                title: $0.title,
                icon: $0.icon,
                disabled: true,
                style: .disabled,
                action: {}
            )
        }

    var footerViewModel: MainFooterViewModel?

    @Published
    private(set) var actionButtonsViewModel: ActionButtonsViewModel?

    private(set) lazy var bottomSheetFooterViewModel = MainBottomSheetFooterViewModel()

    let isMultiWallet: Bool

    private let userWalletModel: UserWalletModel
    private let contextData: AnalyticsContextData?

    private let balanceRestrictionFeatureAvailabilityProvider: BalanceRestrictionFeatureAvailabilityProvider

    private weak var lockedUserWalletDelegate: MainLockedUserWalletDelegate?
    private weak var coordinator: ActionButtonsRoutable?

    private var bag = Set<AnyCancellable>()

    init(
        userWalletModel: UserWalletModel,
        isMultiWallet: Bool,
        lockedUserWalletDelegate: MainLockedUserWalletDelegate?,
        coordinator: ActionButtonsRoutable?
    ) {
        self.userWalletModel = userWalletModel
        self.isMultiWallet = isMultiWallet
        self.lockedUserWalletDelegate = lockedUserWalletDelegate
        self.coordinator = coordinator
        balanceRestrictionFeatureAvailabilityProvider = BalanceRestrictionFeatureAvailabilityProvider(
            userWalletConfig: userWalletModel.config,
            totalBalanceProvider: userWalletModel
        )

        contextData = userWalletModel.analyticsContextData

        if isMultiWallet {
            bindBalanceRestrictionsCheck()
        }

        Analytics.log(event: .mainNoticeWalletUnlock, params: contextData?.analyticsParams ?? [:])
    }

    private func onLockedWalletNotificationTap() {
        Analytics.log(event: .mainNoticeWalletUnlockTapped, params: contextData?.analyticsParams ?? [:])
        openUnlockSheet()
    }

    private func openUnlockSheet() {
        lockedUserWalletDelegate?.openUnlockUserWalletBottomSheet(for: userWalletModel)
    }
}

// MARK: - Action buttons

private extension LockedWalletMainContentViewModel {
    func bindBalanceRestrictionsCheck() {
        balanceRestrictionFeatureAvailabilityProvider.isActionButtonsAvailablePublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, isAvailable in
                viewModel.actionButtonsViewModel = isAvailable ? viewModel.makeActionButtonsViewModel() : nil
            }
            .store(in: &bag)
    }

    func makeActionButtonsViewModel() -> ActionButtonsViewModel? {
        guard let coordinator else {
            return nil
        }

        return .init(
            coordinator: coordinator,
            expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletModel: userWalletModel),
            userWalletModel: userWalletModel
        )
    }
}
