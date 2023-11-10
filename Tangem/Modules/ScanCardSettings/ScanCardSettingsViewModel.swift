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

    private let expectedUserWalletId: Data
    private let sdk: TangemSdk
    private unowned let coordinator: ScanCardSettingsRoutable

    init(expectedUserWalletId: Data, sdk: TangemSdk, coordinator: ScanCardSettingsRoutable) {
        self.expectedUserWalletId = expectedUserWalletId
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
        if let existingCardModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) as? CardViewModel {
            cardInfo.name = existingCardModel.name
        }

        guard let newCardViewModel = CardViewModel(cardInfo: cardInfo) else {
            return
        }

        coordinator.openCardSettings(cardModel: newCardViewModel)
    }
}

// MARK: - Private

extension ScanCardSettingsViewModel {
    func scan(completion: @escaping (Result<CardInfo, Error>) -> Void) {
        isLoading = true
        let task = AppScanTask(shouldAskForAccessCode: true)
        sdk.startSession(with: task, sessionFilter: .cardKitId(expectedUserWalletId)) { [weak self] result in
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
