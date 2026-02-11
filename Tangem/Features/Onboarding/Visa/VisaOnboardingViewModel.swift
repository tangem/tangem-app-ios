//
//  VisaOnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemSdk
import TangemFoundation
import TangemLocalization
import TangemVisa
import struct TangemUIUtils.AlertBinder

protocol VisaOnboardingAlertPresenter: AnyObject {
    @MainActor
    func showAlertAsync(_ alert: AlertBinder) async
    func showAlert(_ alert: AlertBinder)
    @MainActor
    func showContactSupportAlert(for error: Error) async
}

protocol VisaOnboardingRoutable: OnboardingRoutable, OnboardingBrowserRoutable {}

class VisaOnboardingViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    @Published var shouldFireConfetti = false
    @Published var currentProgress: CGFloat = 0
    @Published var steps: [VisaOnboardingStep] = []
    @Published var currentStep: VisaOnboardingStep
    @Published var alert: AlertBinder?
    @Published var cardImage: Image?

    var navigationBarHeight: CGFloat { OnboardingLayoutConstants.navbarSize.height }
    var progressBarHeight: CGFloat { OnboardingLayoutConstants.progressBarHeight }
    var progressBarPadding: CGFloat { OnboardingLayoutConstants.progressBarPadding }

    // MARK: - Subview ViewModels

    lazy var userWalletStorageAgreementViewModel = UserWalletStorageAgreementViewModel(coordinator: self)
    lazy var pushNotificationsViewModel: PushNotificationsPermissionRequestViewModel? = {
        guard let permissionManager = input.pushNotificationsPermissionManager else {
            return nil
        }
        return PushNotificationsPermissionRequestViewModel(permissionManager: permissionManager, delegate: self)
    }()

    // [REDACTED_TODO_COMMENT]
    lazy var welcomeViewModel: VisaOnboardingWelcomeViewModel = VisaOnboardingViewModelsBuilder().buildWelcomeModel(
        activationStatus: visaActivationManager.activationLocalState,
        isAccessCodeSet: visaActivationManager.isAccessCodeSet,
        cardImage: $cardImage,
        delegate: self
    )

    lazy var accessCodeSetupViewModel = VisaOnboardingAccessCodeSetupViewModel(accessCodeValidator: visaActivationManager, delegate: self)
    lazy var walletSelectorViewModel = VisaOnboardingApproveWalletSelectorViewModel(remoteStateProvider: self, delegate: self)
    var tangemWalletApproveViewModel: VisaOnboardingTangemWalletDeployApproveViewModel?
    var walletConnectViewModel: VisaOnboardingWalletConnectViewModel?
    lazy var inProgressViewModel: VisaOnboardingInProgressViewModel? = VisaOnboardingViewModelsBuilder().buildInProgressModel(
        activationRemoteState: visaActivationManager.activationRemoteState,
        delegate: self
    )
    lazy var pinSelectionViewModel: VisaOnboardingPinViewModel = .init(delegate: self)

    // MARK: - Computed properties

    var navigationBarTitle: String {
        currentStep.navigationTitle
    }

    var leftButtonType: VisaOnboardingView.LeftButtonType? {
        switch currentStep {
        case .success:
            return nil
        case .paymentAccountDeployInProgress, .issuerProcessingInProgress:
            return .close
        default:
            return .back
        }
    }

    var isSupportButtonVisible: Bool {
        if currentStep == .success {
            return false
        }

        return true
    }

    private var isOnboardingFinished: Bool {
        currentStep == steps.last
    }

    private let input: OnboardingInput

    private let visaActivationManager: VisaActivationManager
    private var userWalletModel: UserWalletModel?
    private weak var coordinator: VisaOnboardingRoutable?
    private var bag = Set<AnyCancellable>()

    init(
        input: OnboardingInput,
        visaActivationManager: VisaActivationManager,
        coordinator: VisaOnboardingRoutable
    ) {
        self.input = input
        self.visaActivationManager = visaActivationManager
        self.coordinator = coordinator

        if case .visa(let visaSteps) = input.steps {
            steps = visaSteps
            currentStep = visaSteps.first ?? .welcome
        } else {
            currentStep = .welcome
        }

        if case .userWalletModel(let userWalletModel, _, _) = input.cardInput {
            self.userWalletModel = userWalletModel
        }

        if steps.first == .selectWalletForApprove {
            proceedToApproveWalletSelection(animated: false)
        }

        loadImage(imageProvider: input.cardInput.cardImageProvider)

        bindAnalytics()
    }

    func backButtonAction() {
        switch currentStep {
        case .welcome, .welcomeBack, .pushNotifications, .paymentAccountDeployInProgress, .issuerProcessingInProgress, .pinSelection, .saveUserWallet, .selectWalletForApprove:
            showCloseOnboardingAlert()
        case .accessCode:
            guard accessCodeSetupViewModel.goBack() else {
                return
            }

            goToStep(.welcome)
        case .approveUsingTangemWallet:
            goToStep(.selectWalletForApprove)
        case .approveUsingWalletConnect:
            walletConnectViewModel?.cancelStatusUpdates()
            goToStep(.selectWalletForApprove)
        case .success:
            break
        }
    }

    func closeButtonAction() {
        // Subject to change later
        showCloseOnboardingAlert()
    }

    func openSupport() {
        openSupportSheet()
    }

    func finishOnboarding() {
        handleOnboardingFinish()
    }

    private func openSupportSheet() {
        Analytics.log(.requestSupport, params: [.source: .onboarding])

        UIApplication.shared.endEditing()

        let walletModels = userWalletModel.map { AccountsFeatureAwareWalletModelsResolver.walletModels(for: $0) } ?? []

        let dataCollector = DetailsFeedbackDataCollector(
            data: [
                .init(
                    userWalletEmailData: input.cardInput.emailData,
                    walletModels: walletModels
                ),
            ]
        )

        let emailConfig = input.cardInput.config?.emailConfig ?? .visaDefault()

        coordinator?.openMail(
            with: dataCollector,
            recipient: emailConfig.recipient,
            emailType: .visaFeedback(subject: .activation)
        )
    }

    @MainActor
    private func updateUserWalletModel(with card: CardDTO) async {
        let activationStatus = visaActivationManager.activationLocalState
        let cardInfo = CardInfo(
            card: card,
            walletData: .visa(activationStatus),
            associatedCardIds: [card.cardId],
        )

        let userWalletModel = CommonUserWalletModelFactory().makeModel(
            walletInfo: .cardWallet(cardInfo),
            keys: .cardWallet(keys: cardInfo.card.wallets)
        )

        self.userWalletModel = userWalletModel
    }

    private func bindAnalytics() {
        $currentStep
            .removeDuplicates()
            .delay(for: 0.1, scheduler: DispatchQueue.main)
            .receiveValue { step in
                switch step {
                case .welcome, .welcomeBack:
                    Analytics.log(.visaOnboardingActivationScreenOpened)
                case .accessCode:
                    Analytics.log(.visaOnboardingSetAccessCodeScreenOpened)
                case .selectWalletForApprove:
                    Analytics.log(.visaOnboardingChooseWalletScreenOpened)
                case .approveUsingTangemWallet:
                    Analytics.log(.visaOnboardingTangemWalletPrepareScreenOpened)
                case .approveUsingWalletConnect:
                    Analytics.log(.visaOnboardingDAppScreenOpened)
                case .paymentAccountDeployInProgress, .issuerProcessingInProgress:
                    Analytics.log(.visaOnboardingActivationInProgressScreenOpened)
                case .pinSelection:
                    Analytics.log(.visaOnboardingPinCodeScreenOpened)
                case .saveUserWallet:
                    Analytics.log(.visaOnboardingBiometricScreenOpened)
                case .pushNotifications:
                    Analytics.log(.pushNotificationOpened)
                case .success:
                    Analytics.log(.visaOnboardingSuccessScreenOpened)
                }
            }
            .store(in: &bag)
    }
}

// MARK: - Steps navigation logic

private extension VisaOnboardingViewModel {
    func goToNextStep() {
        if isOnboardingFinished {
            handleOnboardingFinish()
            return
        }

        switch currentStep {
        case .welcome:
            goToStep(.accessCode)
        case .welcomeBack(let isAccessCodeSet):
            if isAccessCodeSet {
                // Should be decided in `proceedToApproveWalletSelection()`
                break
            } else {
                goToStep(.accessCode)
            }
        case .accessCode:
            goToStep(.selectWalletForApprove)
        case .selectWalletForApprove, .approveUsingTangemWallet, .approveUsingWalletConnect:
            break
        case .issuerProcessingInProgress, .saveUserWallet, .pushNotifications:
            guard
                let index = steps.firstIndex(of: currentStep),
                index + 1 < steps.count
            else {
                return
            }

            goToStep(steps[index + 1])
        case .paymentAccountDeployInProgress:
            goToStep(.pinSelection)
        case .pinSelection:
            goToStep(.issuerProcessingInProgress)
        case .success:
            closeOnboarding()
        }
    }

    func goToStep(_ step: VisaOnboardingStep, animated: Bool = true) {
        guard let stepIndex = steps.firstIndex(of: step) else {
            VisaLogger.info("Failed to find step \(step)")
            return
        }

        let step = steps[stepIndex]

        DispatchQueue.main.async {
            withAnimation(animated ? .default : nil) {
                self.currentStep = step
                self.currentProgress = CGFloat(stepIndex + 1) / CGFloat(self.steps.count)
            }
        }
    }

    func handleOnboardingFinish() {
        guard let userWalletModel else {
            return
        }

        try? userWalletRepository.add(userWalletModel: userWalletModel)
        coordinator?.onboardingDidFinish(userWalletModel: userWalletModel)
    }
}

// MARK: - In progress logic&navigation

extension VisaOnboardingViewModel: VisaOnboardingInProgressDelegate {
    func canProceedOnboarding() async throws(VisaActivationError) -> Bool {
        let currentState = visaActivationManager.activationRemoteState
        let newLoadedState = try await visaActivationManager.refreshActivationRemoteState()

        return currentState != newLoadedState
    }

    @MainActor
    func proceedFromCurrentRemoteState() async {
        switch visaActivationManager.activationRemoteState {
        case .activated:
            visaActivationManager.setupRefreshTokenSaver(visaRefreshTokenRepository)

            goToNextStep()
        case .blockedForActivation, .failed:
            // [REDACTED_TODO_COMMENT]
            await showAlertAsync("This card was blocked... Is this even possible?..".alertBinder)
        case .paymentAccountDeploying:
            inProgressViewModel = VisaOnboardingViewModelsBuilder().buildInProgressModel(
                activationRemoteState: .paymentAccountDeploying,
                delegate: self
            )
            goToStep(.paymentAccountDeployInProgress)
        case .waitingForActivationFinishing:
            inProgressViewModel = VisaOnboardingViewModelsBuilder().buildInProgressModel(
                activationRemoteState: .waitingForActivationFinishing,
                delegate: self
            )
            goToStep(.issuerProcessingInProgress)
        case .cardWalletSignatureRequired, .customerWalletSignatureRequired:
            // [REDACTED_TODO_COMMENT]
            await showAlertAsync("Invalid card activation state. Please contact support".alertBinder)
        case .waitingPinCode:
            goToStep(.pinSelection)
        }
    }

    func openBrowser(at url: URL, onSuccess: @escaping (URL) -> Void) {
        coordinator?.openBrowser(at: url, onSuccess: onSuccess)
    }

    func navigateToPINCode(withError error: VisaActivationError) async {
        pinSelectionViewModel.setupInvalidPinState()
        goToStep(.pinSelection)
    }
}

// MARK: - Biometry delegate

extension VisaOnboardingViewModel: UserWalletStorageAgreementRoutable {
    func didAgreeToSaveUserWallets() {
        OnboardingUtils().requestBiometrics { [weak self] agreed in
            self?.didAskToSaveUserWallets(agreed: agreed)
            self?.goToNextStep()
        }
    }

    func didDeclineToSaveUserWallets() {
        didAskToSaveUserWallets(agreed: false)
        goToNextStep()
    }

    func didAskToSaveUserWallets(agreed: Bool) {
        visaActivationManager.setupRefreshTokenSaver(visaRefreshTokenRepository)
        OnboardingUtils().processSaveUserWalletRequestResult(agreed: agreed)
        trySaveAccessCode()
    }

    private func trySaveAccessCode() {
        let cardIdToSave: String

        switch input.cardInput {
        case .cardId(let cardId):
            cardIdToSave = cardId
        case .cardInfo(let cardInfo):
            cardIdToSave = cardInfo.card.cardId
        case .userWalletModel(_, let cardId, _):
            cardIdToSave = cardId
        }

        let accessCode = accessCodeSetupViewModel.accessCode
        AccessCodeSaveUtility().trySave(accessCode: accessCode, cardIds: [cardIdToSave])
    }
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension VisaOnboardingViewModel: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        goToNextStep()
    }
}

// MARK: - AccessCodeSetupDelegate

extension VisaOnboardingViewModel: VisaOnboardingAccessCodeSetupDelegate {
    /// We need to show alert in parent view, otherwise it won't be presented
    @MainActor
    func showAlertAsync(_ alert: AlertBinder) async {
        self.alert = alert
    }

    func showAlert(_ alert: AlertBinder) {
        DispatchQueue.main.async {
            self.alert = alert
        }
    }

    @MainActor
    func showContactSupportAlert(for error: Error) async {
        let alert = AlertBuilder.makeAlert(
            title: Localization.commonError,
            message: error.localizedDescription,
            primaryButton: .default(
                Text(Localization.commonContactSupport),
                action: { [weak self] in
                    self?.openSupport()
                }
            ),
            secondaryButton: .destructive(
                Text(Localization.visaOnboardingCancelActivation),
                action: { [weak self] in
                    self?.closeOnboarding()
                }
            )
        )

        await showAlertAsync(alert)
    }

    func useSelectedCode(accessCode: String) async throws {
        try visaActivationManager.saveAccessCode(accessCode: accessCode)
        let activationResponse = try await visaActivationManager.startActivation()
        await updateUserWalletModel(with: .init(card: activationResponse.signedActivationOrder.cardSignedOrder))
        proceedToApproveWalletSelection()
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - Welcome Delegate

extension VisaOnboardingViewModel: VisaOnboardingWelcomeDelegate {
    func openAccessCodeScreen() {
        goToNextStep()
    }

    func continueActivation() async throws {
        let activationResponse = try await visaActivationManager.startActivation()
        await updateUserWalletModel(with: .init(card: activationResponse.signedActivationOrder.cardSignedOrder))
        proceedToApproveWalletSelection()
    }
}

// MARK: - Approve pair search

private extension VisaOnboardingViewModel {
    func proceedToApproveWalletSelection(animated: Bool = true) {
        guard let targetAddress = visaActivationManager.targetApproveAddress else {
            showAlert(OnboardingError.missingTargetApproveAddress.alertBinder)
            return
        }

        guard visaActivationManager.activationRemoteState == .customerWalletSignatureRequired else {
            showAlert(OnboardingError.missingTargetApproveAddress.alertBinder)
            return
        }

        let searchUtility = VisaApprovePairSearchUtility(isTestnet: FeatureStorage.instance.visaAPIType.isTestnet)

        guard
            let approvePair = searchUtility.findApprovePair(
                for: targetAddress,
                userWalletModels: userWalletRepository.models
            )
        else {
            goToStep(.selectWalletForApprove, animated: animated)
            return
        }

        tangemWalletApproveViewModel = .init(
            targetWalletAddress: targetAddress,
            delegate: self,
            dataProvider: self,
            approvePair: approvePair
        )
        goToStep(.approveUsingTangemWallet, animated: animated)
    }
}

// MARK: - ApproveWalletSelector protocols

extension VisaOnboardingViewModel: VisaOnboardingRemoteStateProvider {
    func loadCurrentRemoteState() async throws -> VisaCardActivationRemoteState {
        try await visaActivationManager.refreshActivationRemoteState()
    }
}

extension VisaOnboardingViewModel: VisaOnboardingApproveWalletSelectorDelegate {
    func useExternalWallet() {
        walletConnectViewModel = .init(delegate: self)
        goToStep(.approveUsingWalletConnect)
    }

    func useTangemWallet() {
        // Default value will be removed and guard check will be added, when backend finished implementation
        let targetApproveAddress = visaActivationManager.targetApproveAddress ?? ""
        tangemWalletApproveViewModel = .init(
            targetWalletAddress: targetApproveAddress,
            delegate: self,
            dataProvider: self
        )
        goToStep(.approveUsingTangemWallet)
    }
}

extension VisaOnboardingViewModel: VisaOnboardingTangemWalletApproveDelegate {
    func processSignedData(_ signedData: Data) async throws {
        try await visaActivationManager.sendSignedCustomerWalletApprove(signedData)
        await proceedFromCurrentRemoteState()
    }
}

extension VisaOnboardingViewModel: VisaOnboardingTangemWalletApproveDataProvider {
    func loadDataToSign() async throws -> Data {
        return try await visaActivationManager.getCustomerWalletApproveHash()
    }
}

// MARK: - PinSelectionDelegate

extension VisaOnboardingViewModel: VisaOnboardingPinSelectionDelegate {
    func useSelectedPin(pinCode: String) async throws {
        try await visaActivationManager.setPINCode(pinCode)
        await proceedFromCurrentRemoteState()
    }
}

// MARK: - Close onboarding funcs

private extension VisaOnboardingViewModel {
    func showCloseOnboardingAlert() {
        alert = AlertBuilder.makeExitAlert(
            message: Localization.visaOnboardingCloseAlertMessage,
            discardAction: weakify(self, forFunction: VisaOnboardingViewModel.closeOnboarding)
        )
    }
}

// MARK: - Image loading

private extension VisaOnboardingViewModel {
    func loadImage(imageProvider: WalletImageProviding) {
        runTask(in: self) { model in
            let imageValue = await imageProvider.loadLargeImage()

            await runOnMain {
                withAnimation {
                    model.cardImage = imageValue.image
                }
            }
        }
    }
}

extension VisaOnboardingViewModel {
    enum OnboardingError {
        case missingTargetApproveAddress
        case wrongRemoteState
    }
}
