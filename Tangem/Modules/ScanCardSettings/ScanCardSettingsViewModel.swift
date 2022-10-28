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

    private let cardOnMainWalletId: Data
    private unowned let coordinator: ScanCardSettingsRoutable

    init(cardOnMainWalletId: Data, coordinator: ScanCardSettingsRoutable) {
        self.cardOnMainWalletId = cardOnMainWalletId
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
                self.processSuccessScan(for: cardInfo)
            case let .failure(error):
                self.showErrorAlert(error: error)
            }
        }
    }

    private func processSuccessScan(for cardInfo: CardInfo) {
        let cardModel = CardViewModel(cardInfo: cardInfo)
        guard
            let userWalletId = cardModel.userWalletId,
            userWalletId == cardOnMainWalletId
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
        sdkProvider.setup(with: TangemSdkConfigFactory().makeDefaultConfig())
        sdkProvider.sdk.startSession(with: AppScanTask(targetBatch: nil)) { result in
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
