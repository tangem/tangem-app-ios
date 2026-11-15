//
//  CommonUserWalletLinkBannerManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemLocalization
import TangemUIUtils
import TangemBackendAuthentication

final class CommonUserWalletLinkBannerManager {
    @Injected(\.userWalletLinker) private var userWalletLinker: any UserWalletLinker
    @Injected(\.alertPresenter) private var alertPresenter: any AlertPresenter

    private let userWalletModel: any UserWalletModel

    private var isLinkRequired = false
    private var isLinking = false
    private var onUpdate: (() -> Void)?
    private var registrationStatusTask: Task<Void, Never>?

    init(userWalletModel: any UserWalletModel) {
        self.userWalletModel = userWalletModel
    }

    deinit {
        registrationStatusTask?.cancel()
    }
}

// MARK: - UserWalletLinkBannerManager

extension CommonUserWalletLinkBannerManager: UserWalletLinkBannerManager {
    var event: GeneralNotificationEvent? {
        guard isLinkRequired else {
            return nil
        }

        return .userWalletLinkRequired(
            signingActionButtonType: SigningActionButtonViewTypeBuilder().build(config: userWalletModel.config),
            isLinking: isLinking
        )
    }

    func load(onUpdate: @escaping () -> Void) {
        self.onUpdate = onUpdate

        guard
            FeatureProvider.isAvailable(.walletLinking),
            !userWalletModel.isUserWalletLocked,
            userWalletLinker.isLinkSupported(userWalletModel)
        else {
            return
        }

        let userWalletId = userWalletModel.userWalletId

        registrationStatusTask?.cancel()
        registrationStatusTask = Task { @MainActor [weak self] in
            let updates = await BackendAuthenticationAssembly.retrieveUserWalletRegistrationStatus.updates(id: userWalletId)

            for await isRegistered in updates {
                self?.updateIsLinkRequired(!isRegistered)
            }
        }
    }

    func link() {
        guard !isLinking else {
            return
        }

        isLinking = true
        onUpdate?()

        Analytics.log(.backendAuthButtonLinkWallet, contextParams: .userWallet(userWalletModel.userWalletId))

        userWalletLinker.link(userWalletModel) { [weak self] result in
            self?.handleLinkResult(result)
        }
    }
}

// MARK: - Private

private extension CommonUserWalletLinkBannerManager {
    func updateIsLinkRequired(_ isLinkRequired: Bool) {
        guard self.isLinkRequired != isLinkRequired else {
            return
        }

        self.isLinkRequired = isLinkRequired
        onUpdate?()
    }

    func handleLinkResult(_ result: Result<Void, UserWalletLinkError>) {
        isLinking = false

        switch result {
        case .success:
            isLinkRequired = false
        case .failure(.cancelled):
            break
        case .failure(.notSupported), .failure(.failed):
            alertPresenter.present(alert: AlertBinder(title: Localization.commonSomethingWentWrong, message: Localization.commonTryAgainLater))
        }

        onUpdate?()
    }
}
