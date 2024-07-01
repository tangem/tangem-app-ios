//
//  ScanCardSettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class ScanCardSettingsViewModel: ObservableObject, Identifiable {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published var icon: LoadingValue<CardImageResult> = .loading
    @Published var isLoading: Bool = false
    @Published var alert: AlertBinder?

    private let cardImagePublisher: AnyPublisher<CardImageResult, Never>
    private let cardScanner: CardScanner
    private weak var coordinator: ScanCardSettingsRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        input: ScanCardSettingsViewModel.Input,
        coordinator: ScanCardSettingsRoutable
    ) {
        cardImagePublisher = input.cardImagePublisher
        cardScanner = input.cardScanner
        self.coordinator = coordinator

        bind()
    }

    func bind() {
        cardImagePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, image in
                viewModel.icon = .loaded(image)
            }
            .store(in: &bag)
    }

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
}

// MARK: - Private

extension ScanCardSettingsViewModel {
    func scan(completion: @escaping (Result<CardInfo, Error>) -> Void) {
        isLoading = true
        cardScanner.scanCard { [weak self] result in
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

    func processSuccessScan(for cardInfo: CardInfo) {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()

        guard let userWalletIdSeed = config.userWalletIdSeed else {
            return
        }

        let userWalletId = UserWalletId(with: userWalletIdSeed)

        let input = CardSettingsViewModel.Input(
            userWalletId: userWalletId,
            recoveryInteractor: UserCodeRecoveringCardInteractor(with: cardInfo),
            securityOptionChangeInteractor: SecurityOptionChangingCardInteractor(with: cardInfo),
            factorySettingsResettingCardInteractor: FactorySettingsResettingCardInteractor(with: cardInfo),
            isResetToFactoryAvailable: !config.getFeatureAvailability(.resetToFactory).isHidden,
            backupCardsCount: cardInfo.card.backupStatus?.backupCardsCount ?? 0,
            canTwin: config.hasFeature(.twinning),
            twinInput: makeTwinInput(from: cardInfo, config: config, userWalletId: userWalletId),
            cardIdFormatted: cardInfo.cardIdFormatted,
            cardIssuer: cardInfo.card.issuer.name,
            canDisplayHashesCount: config.hasFeature(.displayHashesCount),
            cardSignedHashes: cardInfo.card.walletSignedHashes,
            canChangeAccessCodeRecoverySettings: config.hasFeature(.accessCodeRecoverySettings),
            resetTofactoryDisabledLocalizedReason: config.getDisabledLocalizedReason(for: .resetToFactory)
        )

        coordinator?.openCardSettings(with: input)
    }

    func makeTwinInput(from cardInfo: CardInfo, config: UserWalletConfig, userWalletId: UserWalletId) -> OnboardingInput? {
        guard let twinData = cardInfo.walletData.twinData,
              let existingModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) else {
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

extension ScanCardSettingsViewModel {
    struct Input {
        let cardImagePublisher: AnyPublisher<CardImageResult, Never>
        let cardScanner: CardScanner
    }
}
