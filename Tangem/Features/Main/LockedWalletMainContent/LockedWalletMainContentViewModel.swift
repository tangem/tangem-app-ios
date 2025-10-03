//
//  LockedWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemUIUtils
import TangemLocalization
import class TangemSdk.BiometricsUtil

protocol MainLockedUserWalletDelegate: AnyObject {
    func openTroubleshooting(actionSheet: ActionSheetBinder)
    func openScanCardManual()
    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType)
}

class LockedWalletMainContentViewModel: ObservableObject {
    @Published var alert: AlertBinder?

    lazy var lockedNotificationInput: NotificationViewInput = {
        let factory = NotificationsFactory()
        let event: GeneralNotificationEvent = .walletLocked
        return .init(
            style: .tappable(hasChevron: true) { [weak self] _ in
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

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable

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
}

// MARK: - Unlocking

private extension LockedWalletMainContentViewModel {
    func unlock() {
        runTask(in: self) { viewModel in
            if viewModel.canUnlockWithBiometry() {
                await viewModel.unlockWithBiometry()
            } else {
                await viewModel.unlockWithFallback()
            }
        }
    }

    func canUnlockWithBiometry() -> Bool {
        guard BiometricsUtil.isAvailable else {
            return false
        }
        if FeatureProvider.isAvailable(.mobileWallet) {
            return AppSettings.shared.useBiometricAuthentication
        } else {
            return AppSettings.shared.saveUserWallets
        }
    }

    func unlockWithBiometry() async {
        Analytics.log(.mainButtonUnlockAllWithBiometrics)

        do {
            let context = try await UserWalletBiometricsUnlocker().unlock()
            let method = UserWalletRepositoryUnlockMethod.biometricsUserWallet(userWalletId: userWalletModel.userWalletId, context: context)
            _ = try await userWalletRepository.unlock(with: method)
        } catch where error.isCancellationError {
            await unlockWithFallback()
        } catch {
            await runOnMain {
                alert = error.alertBinder
            }
        }
    }

    func unlockWithFallback() async {
        let unlocker = UserWalletModelUnlockerFactory.makeUnlocker(userWalletModel: userWalletModel)
        let unlockResult = await unlocker.unlock()
        await handleUnlock(result: unlockResult)
    }

    func handleUnlock(result: UserWalletModelUnlockerResult) async {
        switch result {
        case .error(let error):
            if error.isCancellationError {
                return
            }

            Analytics.logScanError(error, source: .main)
            Analytics.logVisaCardScanErrorIfNeeded(error, source: .main)

            await runOnMain {
                alert = error.alertBinder
            }

        case .scanTroubleshooting:
            await runOnMain {
                Analytics.log(.cantScanTheCard, params: [.source: .main])
                openTroubleshooting()
            }

        case .biometrics(let context):
            do {
                let method = UserWalletRepositoryUnlockMethod.biometrics(context)
                _ = try await userWalletRepository.unlock(with: method)

            } catch {
                await runOnMain {
                    alert = error.alertBinder
                }
            }

        case .success(let userWalletId, let encryptionKey):
            do {
                let method = UserWalletRepositoryUnlockMethod.encryptionKey(userWalletId: userWalletId, encryptionKey: encryptionKey)
                _ = try await userWalletRepository.unlock(with: method)

            } catch {
                await runOnMain {
                    alert = error.alertBinder
                }
            }

        case .userWalletNeedsToDelete:
            assertionFailure("Unexpected state: .userWalletNeedsToDelete should never happen.")
        }
    }
}

// MARK: - Private methods

private extension LockedWalletMainContentViewModel {
    func onLockedWalletNotificationTap() {
        Analytics.log(event: .mainNoticeWalletUnlockTapped, params: contextData?.analyticsParams ?? [:])
        unlock()
    }
}

// MARK: - Navigation

private extension LockedWalletMainContentViewModel {
    func openTroubleshooting() {
        let sheet = ActionSheet(
            title: Text(Localization.alertTroubleshootingScanCardTitle),
            message: Text(Localization.alertTroubleshootingScanCardMessage),
            buttons: [
                .default(Text(Localization.alertButtonTryAgain), action: weakify(self, forFunction: LockedWalletMainContentViewModel.unlock)),
                .default(Text(Localization.commonReadMore), action: weakify(self, forFunction: LockedWalletMainContentViewModel.openScanCardManual)),
                .default(Text(Localization.alertButtonRequestSupport), action: weakify(self, forFunction: LockedWalletMainContentViewModel.requestSupport)),
                .cancel(),
            ]
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak lockedUserWalletDelegate] in
            let actionSheet = ActionSheetBinder(sheet: sheet)
            lockedUserWalletDelegate?.openTroubleshooting(actionSheet: actionSheet)
        }
    }

    func openScanCardManual() {
        Analytics.log(.cantScanTheCardButtonBlog, params: [.source: .main])
        lockedUserWalletDelegate?.openScanCardManual()
    }

    func requestSupport() {
        Analytics.log(.requestSupport, params: [.source: .main])
        failedCardScanTracker.resetCounter()
        lockedUserWalletDelegate?.openMail(with: BaseDataCollector(), recipient: EmailConfig.default.recipient, emailType: .failedToScanCard)
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
