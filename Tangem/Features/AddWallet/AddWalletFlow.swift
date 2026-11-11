//
//  AddWalletFlow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemMobileWalletBackup

@MainActor
final class AddWalletFlow {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    private let analyticsLogger = AddWalletAnalyticsLogger()
    private let socialLoginAnalyticsLogger = MobileSocialLoginAnalyticsLogger()
    private let mobileWalletFeatureProvider = MobileWalletFeatureProvider()
    private let limitUtil = MobileWalletLimitUtil()

    private lazy var socialLoginHelper = MobileSocialLoginHelper(output: self)

    private var isMobileWalletAvailable: Bool {
        mobileWalletFeatureProvider.isAvailable
    }

    private var isSheetPresented: Bool {
        sheetViewModel != nil
    }

    private var sheetViewModel: AddWalletSheetViewModel?
    private var createWalletTask: Task<Void, Never>?
    private var appleSignInTask: Task<Void, Never>?

    private weak var delegate: AddWalletFlowDelegate?

    init(delegate: AddWalletFlowDelegate) {
        self.delegate = delegate
    }

    deinit {
        createWalletTask?.cancel()
        appleSignInTask?.cancel()
    }

    func start() {
        present(sheet: AddWalletSheetViewModel(options: makeOptions(), delegate: self))
    }

    func handleSheetDismiss() {
        guard isSheetPresented else { return }

        logSheetDismissed(reason: .welcomeDismissed)
        sheetViewModel = nil
        delegate?.didFinish()
    }
}

// MARK: - AddWalletSheetDelegate

extension AddWalletFlow: AddWalletSheetDelegate {
    func didSelect(option: AddWalletSheetOption) {
        switch option {
        case .hardwareWallet: selectHardwareWallet()
        case .appleSignIn: selectAppleSignIn()
        case .seedPhraseWallet: selectSeedPhraseWallet()
        case .importWallet: selectImportWallet()
        }
    }
}

// MARK: - MobileImportWalletRoutable

extension AddWalletFlow: MobileImportWalletRoutable {
    func backFromImportWallet() {
        logSheetDismissed(reason: .welcomeDismissBackButton)
        sheetViewModel?.showOptions()
    }

    func closeImportWallet() {
        logSheetDismissed(reason: .welcomeDismissCloseButton)
        dismissSheet()
        delegate?.didFinish()
    }

    func openOnboarding(options: OnboardingCoordinator.Options) {
        dismissSheet()
        delegate?.didRequestOnboarding(options: options)
    }
}

// MARK: - MobileSocialLoginOutput

extension AddWalletFlow: MobileSocialLoginOutput {
    func socialLoginWillPresentSignIn() {
        dismissSheet()
    }

    func socialLoginLoading(_ isLoading: Bool) {
        sheetViewModel?.setLoading(isLoading ? .appleSignIn : nil)
    }

    func socialLoginProcessing(_ isProcessing: Bool) {}

    func socialLoginCompleted(input: MobileSocialWalletInput) {
        let viewModel = MobileSocialWalletViewModel(
            input: input,
            socialAuthProvider: MobileSocialLoginProviderFactory.makeProvider(),
            backupManager: CommonMobileWalletSocialBackupManager(destination: .iCloud),
            coordinator: self
        )
        delegate?.didRequestSocialWallet(viewModel: viewModel)
    }

    func socialLoginFailed(failure: MobileSocialWalletFailure) {
        socialLoginAnalyticsLogger.logErrorShown(message: failure.message)
        alertPresenter.present(alert: failure.makeAlert())
    }
}

// MARK: - MobileSocialWalletRoutable

extension AddWalletFlow: MobileSocialWalletRoutable {
    func socialWalletOpenMain(userWalletModel: UserWalletModel) {
        delegate?.didAdd(userWalletModel: userWalletModel)
    }

    func socialWalletFailed(failure: MobileSocialWalletFailure) {
        socialLoginAnalyticsLogger.logErrorShown(message: failure.message)
        alertPresenter.present(alert: failure.makeAlert())
    }

    func socialWalletClose() {
        delegate?.didCloseSocialWallet()
    }
}

// MARK: - Option handling

private extension AddWalletFlow {
    func makeOptions() -> [AddWalletSheetOption] {
        var options: [AddWalletSheetOption] = [.hardwareWallet]

        if FeatureProvider.isAvailable(.mobileSocialLogin) {
            options.append(.appleSignIn)
        }

        options.append(contentsOf: [.seedPhraseWallet, .importWallet])
        return options
    }

    func selectHardwareWallet() {
        analyticsLogger.logHardwareWalletTap()
        dismissSheet()
        delegate?.didRequestHardwareWallet()
    }

    func selectAppleSignIn() {
        analyticsLogger.logAppleSignInTap()

        guard isMobileWalletAvailable else {
            analyticsLogger.logAppleSignInMinOSNotSupportedNotice()
            alertPresenter.present(alert: mobileWalletFeatureProvider.makeRestrictionAlert())
            return
        }

        if let restriction = limitUtil.restriction(for: .socialLogin) {
            presentLimitRestriction(restriction)
            return
        }

        signInWithApple()
    }

    func selectSeedPhraseWallet() {
        analyticsLogger.logSeedPhraseWalletTap()

        guard isMobileWalletAvailable else {
            alertPresenter.present(alert: mobileWalletFeatureProvider.makeRestrictionAlert())
            return
        }

        if let restriction = limitUtil.restriction(for: .create) {
            presentLimitRestriction(restriction)
            return
        }

        createMobileWallet()
    }

    func selectImportWallet() {
        analyticsLogger.logImportWalletTap()

        guard isMobileWalletAvailable else {
            alertPresenter.present(alert: mobileWalletFeatureProvider.makeRestrictionAlert())
            return
        }

        if let restriction = limitUtil.restriction(for: .import) {
            presentLimitRestriction(restriction)
            return
        }

        let importViewModel = MobileImportWalletViewModel(mode: .embedded, coordinator: self)
        sheetViewModel?.showImportWallet(importViewModel)
    }

    func presentLimitRestriction(_ restriction: MobileWalletLimitUtil.Restriction) {
        analyticsLogger.logMobileWalletLimitNotice(restriction: restriction)
        alertPresenter.present(alert: restriction.makeAlert())
    }
}

// MARK: - Mobile wallet creation

private extension AddWalletFlow {
    func createMobileWallet() {
        guard createWalletTask == nil else { return }

        sheetViewModel?.setLoading(.seedPhraseWallet)

        createWalletTask = Task { @MainActor [weak self] in
            defer { self?.finishMobileWalletCreation() }

            let creationUtil = MobileCreationUtil()

            do {
                let userWalletModel = try await creationUtil.makeCreatedModel()

                guard let self, !Task.isCancelled else {
                    creationUtil.discard(userWalletModel)
                    return
                }

                try completeMobileWalletCreation(of: userWalletModel, using: creationUtil)
            } catch {
                self?.handleMobileWalletCreationFailure(error)
            }
        }
    }

    func completeMobileWalletCreation(of userWalletModel: UserWalletModel, using creationUtil: MobileCreationUtil) throws {
        try creationUtil.store(userWalletModel)
        analyticsLogger.logWalletCreated()
        pushNotificationsInteractor.suppressAfterLoginRequestsInCurrentSession()

        dismissSheet()
        delegate?.didAdd(userWalletModel: userWalletModel)
    }

    func handleMobileWalletCreationFailure(_ error: Error) {
        AppLogger.error("Add wallet: mobile wallet creation failed", error: error)
        alertPresenter.present(alert: error.alertBinder)
    }

    func finishMobileWalletCreation() {
        sheetViewModel?.setLoading(nil)
        createWalletTask = nil
    }
}

// MARK: - Apple sign in

private extension AddWalletFlow {
    func signInWithApple() {
        guard appleSignInTask == nil else { return }

        let helper = socialLoginHelper

        appleSignInTask = Task { @MainActor [weak self] in
            let result = await helper.signIn()

            guard let self else { return }

            appleSignInTask = nil
            handleAppleSignInResult(result)
        }
    }

    func handleAppleSignInResult(_ result: MobileSocialLoginResult) {
        switch result {
        case .completed, .failed(isSignInPresented: false):
            break
        case .cancelled, .failed(isSignInPresented: true):
            delegate?.didFinish()
        }
    }
}

// MARK: - Sheets

private extension AddWalletFlow {
    func present(sheet: AddWalletSheetViewModel) {
        sheetViewModel = sheet
        delegate?.present(sheet: sheet)
    }

    func dismissSheet() {
        guard isSheetPresented else { return }

        sheetViewModel = nil
        delegate?.dismissSheet()
    }

    func logSheetDismissed(reason: Analytics.ParameterValue) {
        guard let sheetViewModel else { return }

        let visibleSheet: Analytics.ParameterValue = switch sheetViewModel.state {
        case .options: .addWallet
        case .importWallet: .welcomeImportExisting
        }

        analyticsLogger.logSheetDismissed(sheet: visibleSheet, reason: reason)
    }
}
