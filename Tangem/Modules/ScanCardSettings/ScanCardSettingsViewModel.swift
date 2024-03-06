//
//  ScanCardSettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSdk

final class ScanCardSettingsViewModel: ObservableObject, Identifiable {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    let id = UUID()

    @Published var isLoading: Bool = false
    @Published var alert: AlertBinder?

    private let sessionFilter: SessionFilter
    private let sdk: TangemSdk
    private weak var coordinator: ScanCardSettingsRoutable?

    init(sessionFilter: SessionFilter, sdk: TangemSdk, coordinator: ScanCardSettingsRoutable) {
        self.sessionFilter = sessionFilter
        self.sdk = sdk
        self.coordinator = coordinator
    }
}

// MARK: - View Output

extension ScanCardSettingsViewModel {
    func scanCard() {
        scan { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let cardInfo):
                processSuccessScan(for: cardInfo)
            case .failure(let error):
                showErrorAlert(error: error)
            }
        }
    }

    private func processSuccessScan(for cardInfo: CardInfo) {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()

        guard let userWalletIdSeed = config.userWalletIdSeed else {
            return
        }

        let userWalletId = UserWalletId(with: userWalletIdSeed)

        var cardInfo = cardInfo

        // [REDACTED_TODO_COMMENT]
        if let existingCardModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) as? CommonUserWalletModel {
            cardInfo.name = existingCardModel.name
        }

        guard let newCardViewModel = CommonUserWalletModel(cardInfo: cardInfo) else {
            return
        }

        let input = CardSettingsViewModel.Input(
            userWalletId: newCardViewModel.userWalletId,
            recoveryInteractor: UserCodeRecoveringCardInteractor(with: newCardViewModel.cardInfo),
            securityOptionChangeInteractor: SecurityOptionChangingCardInteractor(with: newCardViewModel.cardInfo),
            factorySettingsResettingCardInteractor: FactorySettingsResettingCardInteractor(with: newCardViewModel.cardInfo),
            isResetToFactoryAvailable: !newCardViewModel.config.getFeatureAvailability(.resetToFactory).isHidden,
            hasBackupCards: newCardViewModel.hasBackupCards,
            canTwin: newCardViewModel.config.hasFeature(.twinning),
            twinInput: newCardViewModel.twinInput,
            cardIdFormatted: newCardViewModel.cardInfo.cardIdFormatted,
            cardIssuer: newCardViewModel.cardInfo.card.issuer.name,
            canDisplayHashesCount: newCardViewModel.config.hasFeature(.displayHashesCount),
            cardSignedHashes: newCardViewModel.cardInfo.card.walletSignedHashes,
            canChangeAccessCodeRecoverySettings: newCardViewModel.config.hasFeature(.accessCodeRecoverySettings),
            resetTofactoryDisabledLocalizedReason: newCardViewModel.config.getDisabledLocalizedReason(for: .resetToFactory)
        )

        coordinator?.openCardSettings(with: input)
    }
}

// MARK: - Private

extension ScanCardSettingsViewModel {
    func scan(completion: @escaping (Result<CardInfo, Error>) -> Void) {
        isLoading = true
        let task = AppScanTask(shouldAskForAccessCode: true)
        sdk.startSession(with: task, filter: sessionFilter) { [weak self] result in
            self?.isLoading = false

            switch result {
            case .failure(let error):
                guard !error.isUserCancelled else {
                    return
                }

                AppLog.shared.error(error)
                completion(.failure(error))
            case .success(let response):
                completion(.success(response.getCardInfo()))
            }
        }
    }

    func showErrorAlert(error: Error) {
        alert = AlertBuilder.makeOkErrorAlert(message: error.localizedDescription)
    }
}
