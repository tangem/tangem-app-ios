//
//  MockedCardScanner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import class UIKit.UIAlertController
import class UIKit.UIAlertAction
import Combine
import TangemSdk

private typealias SelectionHandler = (Result<MockedCardScanner.Option, TangemSdkError>) -> Void

class MockedCardScanner {
    private let scanner: CardScanner

    init(scanner: CardScanner = CommonCardScanner()) {
        self.scanner = scanner
    }

    private func selectOption(_ handler: @escaping SelectionHandler) {
        let vc = UIAlertController(
            title: "Select option",
            message: "Session filtering is not supported in mocked mode",
            preferredStyle: .actionSheet
        )

        let action = UIAlertAction(
            title: "Scan",
            style: .default,
            handler: { [weak self] _ in self?.scan(handler) }
        )
        vc.addAction(action)

        for mock in CardMock.allCases {
            let action = UIAlertAction(
                title: mock.rawValue,
                style: .default,
                handler: { _ in handler(.success(.cardMock(mock))) }
            )
            action.accessibilityIdentifier = mock.accessibilityIdentifier
            vc.addAction(action)
        }

        let cobrandMockOption = UIAlertAction(
            title: "Cobrand mock",
            style: .default,
            handler: { [weak self] _ in self?.promptCobrandMock(handler) }
        )
        vc.addAction(cobrandMockOption)

        let jsonOption = UIAlertAction(
            title: "Custom JSON",
            style: .default,
            handler: { [weak self] _ in self?.promptJSON(handler) }
        )
        vc.addAction(jsonOption)

        vc.addAction(
            UIAlertAction(
                title: Localization.commonCancel,
                style: .cancel,
                handler: { _ in handler(.failure(TangemSdkError.userCancelled)) }
            ))

        AppPresenter.shared.show(vc)
    }

    private func promptCobrandMock(_ handler: @escaping SelectionHandler) {
        let vc = UIAlertController(
            title: "Configure cobrand mock",
            message: "wallet2 mock will be used with the specified batch ID and cards count",
            preferredStyle: .alert
        )

        vc.addTextField { textField in
            textField.placeholder = "Batch ID (e.g. AF07)"
        }

        vc.addTextField { textField in
            textField.placeholder = "Cards count (default: 2)"
            textField.keyboardType = .numberPad
        }

        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            if let batchId = vc.textFields?[0].text, !batchId.isEmpty {
                let cardsCount = Int(vc.textFields?[1].text ?? "") ?? 2
                handler(.success(.cobrandMock(batchId: batchId, cardsCount: cardsCount)))
            } else {
                handler(.failure(.userCancelled))
            }
        }

        vc.addAction(submitAction)

        vc.addAction(
            UIAlertAction(
                title: Localization.commonCancel,
                style: .cancel,
                handler: { _ in handler(.failure(TangemSdkError.userCancelled)) }
            ))

        AppPresenter.shared.show(vc)
    }

    private func promptJSON(_ handler: @escaping SelectionHandler) {
        let vc = UIAlertController(
            title: "Enter card json",
            message: "WalletData is not supported for now",
            preferredStyle: .alert
        )

        vc.addTextField()

        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            if let jsonString = vc.textFields?[0].text {
                handler(.success(.json(jsonString)))
            } else {
                handler(.failure(.userCancelled))
            }
        }

        vc.addAction(submitAction)

        vc.addAction(
            UIAlertAction(
                title: Localization.commonCancel,
                style: .cancel,
                handler: { _ in handler(.failure(TangemSdkError.userCancelled)) }
            ))

        AppPresenter.shared.show(vc)
    }

    private func scan(_ handler: @escaping SelectionHandler) {
        scanner.scanCard { result in
            switch result {
            case .success(let response):
                handler(.success(.scan(response)))
            case .failure(let error):
                handler(.failure(error))
            }
        }
    }
}

extension MockedCardScanner: CardScanner {
    func scanCard(completion: @escaping (Result<AppScanTaskResponse, TangemSdkError>) -> Void) {
        DispatchQueue.main.async {
            self.selectOption { result in
                switch result {
                case .success(let option):
                    switch option {
                    case .scan(let response):
                        completion(.success(response))
                    case .cardMock(let mock):
                        do {
                            let environment = ProcessInfo.processInfo.environment
                            let batchIdOverride = environment["UITEST_MOCK_CARD_BATCH_ID"].flatMap { $0.isEmpty ? nil : $0 }
                            let firmwareOverride = environment["UITEST_MOCK_CARD_FIRMWARE"].flatMap { $0.isEmpty ? nil : $0 }
                            let card: Card
                            if batchIdOverride != nil || firmwareOverride != nil {
                                card = try mock.card(batchIdOverride: batchIdOverride, firmwareOverride: firmwareOverride)
                            } else {
                                card = mock.card
                            }
                            let response = AppScanTaskResponse(
                                card: card,
                                walletData: mock.walletData,
                                primaryCard: nil
                            )

                            completion(.success(response))
                        } catch {
                            completion(.failure(.underlying(error: error)))
                        }
                    case .cobrandMock(let batchId, let cardsCount):
                        do {
                            let card = try CardMock.wallet2.cobrandMock(batchId: batchId, cardsCount: cardsCount)
                            let response = AppScanTaskResponse(
                                card: card,
                                walletData: .none,
                                primaryCard: nil
                            )

                            completion(.success(response))
                        } catch {
                            completion(.failure(.underlying(error: error)))
                        }
                    case .json(let jsonString):
                        guard let jsonData = jsonString.data(using: .utf8) else {
                            completion(.failure(.underlying(error: Error.jsonToDataError)))
                            return
                        }

                        do {
                            let decodedCard = try JSONDecoder.tangemSdkDecoder.decode(Card.self, from: jsonData)
                            let response = AppScanTaskResponse(
                                card: decodedCard,
                                walletData: .none,
                                primaryCard: nil
                            )

                            completion(.success(response))
                        } catch {
                            completion(.failure(.underlying(error: error)))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    func scanCardPublisher() -> AnyPublisher<AppScanTaskResponse, TangemSdkError> {
        Deferred {
            Future { [weak self] promise in
                self?.scanCard(completion: promise)
            }
        }
        .eraseToAnyPublisher()
    }
}

extension MockedCardScanner {
    enum Option {
        case scan(AppScanTaskResponse)
        case cardMock(CardMock)
        case cobrandMock(batchId: String, cardsCount: Int)
        case json(String)
    }

    enum Error: String, Swift.Error, LocalizedError {
        case jsonToDataError

        var errorDescription: String? {
            return rawValue
        }
    }
}
