//
//  AllServicesViewModel.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemLocalization
import struct TangemUIUtils.ConfirmationDialogViewModel

final class AllServicesViewModel: ObservableObject {
    @Published private(set) var sections: [Section] = []
    @Published private(set) var isReferralAvailable = false
    @Published private(set) var isScanning = false
    @Published var scanTroubleshootingDialog: ConfirmationDialogViewModel?

    // [REDACTED_TODO_COMMENT]
    let title = "All services"
    let subtitle = "Everything available to you in one place.\nAdd what you need, when you need it."
    let referralAccessibilityLabel = Localization.detailsReferralTitle
    let actions: [AllServicesAction]

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable
    @Injected(\.alertPresenter) private var alertPresenter: any AlertPresenter

    private var analyticsParams: [Analytics.ParameterKey: Analytics.ParameterValue] {
        [.source: .allServices]
    }

    private let layout = AllServicesLayout.standard
    private let itemsProvider: AllServicesItemsProvider
    private let referralEntryProvider: ReferralServiceEntryProvider
    private weak var coordinator: AllServicesRoutable?
    private var bag = Set<AnyCancellable>()

    init(
        itemsProvider: AllServicesItemsProvider,
        referralEntryProvider: ReferralServiceEntryProvider,
        coordinator: AllServicesRoutable
    ) {
        self.itemsProvider = itemsProvider
        self.referralEntryProvider = referralEntryProvider
        self.coordinator = coordinator
        actions = itemsProvider.actions

        bind()
    }

    func select(_ action: AllServicesAction) {
        switch action.id {
        case .addWallet:
            coordinator?.openAddWallet()
        case .buyTangem:
            coordinator?.openShop()
        }
    }

    func select(_ item: AllServicesItem) {
        switch item.id {
        case .cryptoAccount:
            coordinator?.openCryptoAccountForm()
        case .jointAccount:
            coordinator?.openJointAccountCreation()
        }
    }

    func openReferral() {
        coordinator?.openReferral(wallets: referralEntryProvider.wallets)
    }

    func close() {
        coordinator?.closeAllServices()
    }
}

// MARK: - Card scanning

extension AllServicesViewModel {
    func scanCard() {
        isScanning = true

        runTask(in: self) { @MainActor viewModel in
            let cardScanner = CardScannerFactory().makeDefaultScanner()
            let userWalletCardScanner = UserWalletCardScanner(scanner: cardScanner)
            let result = await userWalletCardScanner.scanCard()

            viewModel.isScanning = false

            switch result {
            case .error(let error) where error.isCancellationError:
                break

            case .error(let error):
                Analytics.logScanError(error, source: .allServices)
                Analytics.logVisaCardScanErrorIfNeeded(error, source: .allServices)
                viewModel.alertPresenter.present(alert: error.alertBinder)

            case .onboarding(let input, _):
                Analytics.log(
                    .cardWasScanned,
                    params: viewModel.analyticsParams,
                    contextParams: input.cardInput.getContextParams()
                )
                viewModel.coordinator?.openOnboardingModal(with: input)

            case .scanTroubleshooting:
                Analytics.log(.cantScanTheCard, params: viewModel.analyticsParams)
                viewModel.openTroubleshooting()

            case .success(let cardInfo):
                Analytics.log(
                    .cardWasScanned,
                    params: viewModel.analyticsParams,
                    contextParams: .custom(cardInfo.analyticsContextData)
                )

                do {
                    try viewModel.addUserWallet(cardInfo: cardInfo)
                    viewModel.coordinator?.closeAllServices()
                } catch {
                    viewModel.alertPresenter.present(alert: error.alertBinder)
                }
            }
        }
    }
}

// MARK: - Private

private extension AllServicesViewModel {
    func bind() {
        itemsProvider
            .itemsPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, items in
                viewModel.apply(items)
            }
            .store(in: &bag)

        referralEntryProvider
            .isAvailablePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, isAvailable in
                viewModel.isReferralAvailable = isAvailable
            }
            .store(in: &bag)
    }

    func apply(_ items: [AllServicesItem]) {
        let itemsByID = items.keyedFirst(by: \.id)

        sections = layout.sections.compactMap { section in
            let rows = section.items.compactMap { itemsByID[$0] }
            return rows.isEmpty ? nil : Section(id: section.id, title: section.id.title, items: rows)
        }
    }

    func addUserWallet(cardInfo: CardInfo) throws {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)

        guard let userWalletId = UserWalletId(config: config) else {
            throw UserWalletRepositoryError.cantUnlockWallet
        }

        if userWalletRepository.models.contains(where: { $0.userWalletId == userWalletId }) {
            throw UserWalletRepositoryError.duplicateWalletAdded
        }

        guard let newUserWalletModel = CommonUserWalletModelFactory().makeModel(
            walletInfo: .cardWallet(cardInfo),
            keys: .cardWallet(keys: cardInfo.card.wallets)
        ) else {
            throw UserWalletRepositoryError.cantUnlockWallet
        }

        let walletAddedLogger = WalletAddedAnalyticsLogger()

        if AppSettings.shared.saveUserWallets {
            try userWalletRepository.add(userWalletModel: newUserWalletModel)
        } else {
            let currentUserWalletId = userWalletRepository.selectedModel?.userWalletId
            try userWalletRepository.add(userWalletModel: newUserWalletModel)

            if let currentUserWalletId {
                userWalletRepository.delete(userWalletId: currentUserWalletId)
            }
        }

        walletAddedLogger.logIfNeeded(source: .allServices, contextData: cardInfo.analyticsContextData)
    }
}

// MARK: - Section

extension AllServicesViewModel {
    struct Section: Identifiable {
        let id: AllServicesSectionID
        let title: String
        let items: [AllServicesItem]
    }
}

// MARK: - Section titles

private extension AllServicesSectionID {
    var title: String {
        switch self {
        case .account: Localization.commonAccount
        }
    }
}

// MARK: - Scan troubleshooting

private extension AllServicesViewModel {
    func openTroubleshooting() {
        let tryAgainButton = ConfirmationDialogViewModel.Button(
            title: Localization.alertButtonTryAgain,
            action: weakify(self, forFunction: AllServicesViewModel.tryAgain)
        )

        let readMoreButton = ConfirmationDialogViewModel.Button(
            title: Localization.commonReadMore,
            action: weakify(self, forFunction: AllServicesViewModel.openScanCardManual)
        )

        let requestSupportButton = ConfirmationDialogViewModel.Button(
            title: Localization.alertButtonRequestSupport,
            action: weakify(self, forFunction: AllServicesViewModel.requestSupport)
        )

        scanTroubleshootingDialog = ConfirmationDialogViewModel(
            title: Localization.alertTroubleshootingScanCardTitle,
            subtitle: Localization.alertTroubleshootingScanCardMessage,
            buttons: [
                tryAgainButton,
                readMoreButton,
                requestSupportButton,
                ConfirmationDialogViewModel.Button.cancel,
            ]
        )
    }

    func tryAgain() {
        Analytics.log(.cantScanTheCardTryAgainButton, params: analyticsParams)
        scanCard()
    }

    func openScanCardManual() {
        Analytics.log(.cantScanTheCardButtonBlog, params: analyticsParams)
        coordinator?.openScanCardManual()
    }

    func requestSupport() {
        Analytics.log(.requestSupport, params: analyticsParams)
        failedCardScanTracker.resetCounter()
        coordinator?.openMail(with: BaseDataCollector(), recipient: EmailConfig.default.recipient)
    }
}
