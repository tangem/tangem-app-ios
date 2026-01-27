//
//  LockedWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemUIUtils
import TangemLocalization
import class TangemSdk.BiometricsUtil

protocol MainLockedUserWalletDelegate: AnyObject {
    func openTroubleshooting(confirmationDialog: ConfirmationDialogViewModel)
    func openScanCardManual()
    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType)
}

final class LockedWalletMainContentViewModel: ObservableObject {
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

    private let signInAnalyticsLogger = SignInAnalyticsLogger()

    private let userWalletModel: UserWalletModel
    private let contextData: AnalyticsContextData?

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

        contextData = userWalletModel.analyticsContextData

        if isMultiWallet {
            setupActionButtons()
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
            let userWalletModel = try await userWalletRepository.unlock(with: method)
            signInAnalyticsLogger.logSignInEvent(signInType: .biometrics, userWalletModel: userWalletModel)

        } catch where error.isCancellationError {
            await unlockWithFallback()
        } catch let repositoryError as UserWalletRepositoryError {
            if repositoryError == .biometricsChanged {
                await unlockWithFallback()
            } else {
                await runOnMain {
                    alert = repositoryError.alertBinder
                }
            }
        } catch {
            await runOnMain {
                alert = error.alertBinder
            }
        }
    }

    func unlockWithFallback() async {
        let unlocker = UserWalletModelUnlockerFactory.makeUnlocker(userWalletModel: userWalletModel)
        let unlockResult = await unlocker.unlock()
        await handleUnlock(result: unlockResult, signInType: unlocker.analyticsSignInType)
    }

    func handleUnlock(result: UserWalletModelUnlockerResult, signInType: Analytics.SignInType) async {
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
                let userWalletModel = try await userWalletRepository.unlock(with: method)
                signInAnalyticsLogger.logSignInEvent(signInType: signInType, userWalletModel: userWalletModel)

            } catch {
                await runOnMain {
                    alert = error.alertBinder
                }
            }

        case .success(let userWalletId, let encryptionKey):
            Analytics.log(
                .cardWasScanned,
                params: [.source: Analytics.CardScanSource.mainUnlock.cardWasScannedParameterValue],
                contextParams: .userWallet(userWalletId)
            )

            do {
                let method = UserWalletRepositoryUnlockMethod.encryptionKey(userWalletId: userWalletId, encryptionKey: encryptionKey)
                let userWalletModel = try await userWalletRepository.unlock(with: method)
                signInAnalyticsLogger.logSignInEvent(signInType: signInType, userWalletModel: userWalletModel)

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
        let tryAgainButton = ConfirmationDialogViewModel.Button(title: Localization.alertButtonTryAgain) { [weak self] in
            self?.unlock()
        }

        let readMoreButton = ConfirmationDialogViewModel.Button(title: Localization.commonReadMore) { [weak self] in
            self?.openScanCardManual()
        }

        let requestSupportButton = ConfirmationDialogViewModel.Button(title: Localization.alertButtonRequestSupport) { [weak self] in
            self?.requestSupport()
        }

        let viewModel = ConfirmationDialogViewModel(
            title: Localization.alertTroubleshootingScanCardTitle,
            subtitle: Localization.alertTroubleshootingScanCardMessage,
            buttons: [
                tryAgainButton,
                readMoreButton,
                requestSupportButton,
                ConfirmationDialogViewModel.Button.cancel,
            ]
        )

        lockedUserWalletDelegate?.openTroubleshooting(confirmationDialog: viewModel)
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
    func setupActionButtons() {
        actionButtonsViewModel = makeActionButtonsViewModel()
    }

    func makeActionButtonsViewModel() -> ActionButtonsViewModel? {
        guard let coordinator else {
            return nil
        }

        return .init(
            coordinator: coordinator,
            expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletId: userWalletModel.userWalletId),
            userWalletModel: userWalletModel
        )
    }
}
