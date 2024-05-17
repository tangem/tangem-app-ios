//
//  CardSettingsScanUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CardSettingsScanUtil {
    private let cardScanner: CardScanner
    private let userWalletModels: [UserWalletModel]

    init(cardScanner: CardScanner, userWalletModels: [UserWalletModel]) {
        self.cardScanner = cardScanner
        self.userWalletModels = userWalletModels
    }

    func scan(completion: @escaping (Result<CardSettingsViewModel.Input, Error>) -> Void) {
        cardScanner.scanCard { result in
            switch result {
            case .failure(let error):
                guard !error.isUserCancelled else {
                    return
                }

                AppLog.shared.error(error)
                completion(.failure(error))
            case .success(let response):
                if let input = processSuccessScan(for: response.getCardInfo()) {
                    completion(.success(input))
                } else {
                    completion(.failure(CommonError.noData))
                }
            }
        }
    }
}

private extension CardSettingsScanUtil {
    func processSuccessScan(for cardInfo: CardInfo) -> CardSettingsViewModel.Input? {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()

        guard let userWalletIdSeed = config.userWalletIdSeed else {
            return nil
        }

        let userWalletId = UserWalletId(with: userWalletIdSeed)

        return CardSettingsViewModel.Input(
            userWalletId: userWalletId,
            recoveryInteractor: UserCodeRecoveringCardInteractor(with: cardInfo),
            securityOptionChangeInteractor: SecurityOptionChangingCardInteractor(with: cardInfo),
            factorySettingsResettingCardInteractor: FactorySettingsResettingCardInteractor(with: cardInfo),
            isResetToFactoryAvailable: !config.getFeatureAvailability(.resetToFactory).isHidden,
            hasBackupCards: cardInfo.card.backupStatus?.isActive ?? false,
            canTwin: config.hasFeature(.twinning),
            twinInput: makeTwinInput(from: cardInfo, config: config, userWalletId: userWalletId),
            cardIdFormatted: cardInfo.cardIdFormatted,
            cardIssuer: cardInfo.card.issuer.name,
            canDisplayHashesCount: config.hasFeature(.displayHashesCount),
            cardSignedHashes: cardInfo.card.walletSignedHashes,
            canChangeAccessCodeRecoverySettings: config.hasFeature(.accessCodeRecoverySettings),
            resetTofactoryDisabledLocalizedReason: config.getDisabledLocalizedReason(for: .resetToFactory)
        )
    }

    func makeTwinInput(from cardInfo: CardInfo, config: UserWalletConfig, userWalletId: UserWalletId) -> OnboardingInput? {
        guard let twinData = cardInfo.walletData.twinData,
              let existingModel = userWalletModels.first(where: { $0.userWalletId == userWalletId }) else {
            return nil
        }

        let factory = TwinInputFactory(
            firstCardId: cardInfo.card.cardId,
            cardInput: .userWalletModel(existingModel),
            userWalletToDelete: userWalletId,
            twinData: twinData,
            sdkFactory: config
        )
        return factory.makeTwinInput()
    }
}
