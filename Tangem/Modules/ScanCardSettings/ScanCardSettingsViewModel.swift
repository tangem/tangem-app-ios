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
    @Injected(\.tangemSdkProvider) private var sdkProvider: TangemSdkProviding

    let id = UUID()

    @Published var isLoading: Bool = false
    @Published var alert: AlertBinder?

    private let expectedUserWalletId: Data
    private unowned let coordinator: ScanCardSettingsRoutable

    init(expectedUserWalletId: Data, coordinator: ScanCardSettingsRoutable) {
        self.expectedUserWalletId = expectedUserWalletId
        self.coordinator = coordinator
    }
}

// MARK: - View Output

extension ScanCardSettingsViewModel {
    func scanCard() {
        scan { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .success(cardInfo):
                let config = UserWalletConfigFactory(cardInfo).makeConfig()
                let cardModel = CardViewModel(cardInfo: cardInfo, config: config)
                cardModel.didScan() // [REDACTED_TODO_COMMENT]
                self.processSuccessScan(for: cardInfo)
            case let .failure(error):
                self.showErrorAlert(error: error)
            }
        }
    }

    private func processSuccessScan(for cardInfo: CardInfo) {
        let cardModel = CardViewModel(cardInfo: cardInfo, config: UserWalletConfigFactory(cardInfo).makeConfig())
        guard
            let userWalletId = cardModel.userWalletId,
            userWalletId == expectedUserWalletId
        else {
            showErrorAlert(error: AppError.wrongCardWasTapped)
            return
        }

        cardModel.didScan() // [REDACTED_TODO_COMMENT]
        self.coordinator.openCardSettings(cardModel: cardModel)
    }
}

// MARK: - Private

extension ScanCardSettingsViewModel {
    func scan(completion: @escaping (Result<CardInfo, Error>) -> Void) {
        sdkProvider.sdk.startSession(with: AppScanTask(targetBatch: nil, allowsAccessCodeFromRepository: true)) { result in
            switch result {
            case let .failure(error):
                guard !error.isUserCancelled else {
                    return
                }

                Analytics.logCardSdkError(error, for: .scan)
                completion(.failure(error))
            case .success(let response):
                completion(.success(response.getCardInfo()))
            }
        }
    }

    func showErrorAlert(error: Error) {
        self.alert = AlertBuilder.makeOkErrorAlert(message: error.localizedDescription)
    }
}
