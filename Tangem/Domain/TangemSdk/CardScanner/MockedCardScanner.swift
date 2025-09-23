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

        let hybridAction = UIAlertAction(
            title: "Hybrid Attestation",
            style: .default,
            handler: { [weak self] _ in self?.promptHybridAttestation(handler) }
        )
        vc.addAction(hybridAction)

        for mock in CardMock.allCases {
            let action = UIAlertAction(
                title: mock.rawValue,
                style: .default,
                handler: { _ in handler(.success(.cardMock(mock))) }
            )
            action.accessibilityIdentifier = mock.accessibilityIdentifier
            vc.addAction(action)
        }

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

    private func promptHybridAttestation(_ handler: @escaping SelectionHandler) {
        let vc = UIAlertController(
            title: "Select Mock Card for Real Attestation",
            message: "This will perform real attestation requests to backend with mock card data",
            preferredStyle: .actionSheet
        )

        for mock in CardMock.allCases {
            let action = UIAlertAction(
                title: "\(mock.rawValue) (Real Backend Attestation)",
                style: .default,
                handler: { _ in handler(.success(.realAttestation(mock))) }
            )
            action.accessibilityIdentifier = "\(mock.accessibilityIdentifier)_real_attestation"
            vc.addAction(action)
        }

        vc.addAction(
            UIAlertAction(
                title: Localization.commonCancel,
                style: .cancel,
                handler: { _ in handler(.failure(TangemSdkError.userCancelled)) }
            ))

        AppPresenter.shared.show(vc)
    }

    private func performRealAttestation(with mock: CardMock, completion: @escaping (Result<AppScanTaskResponse, TangemSdkError>) -> Void) {
        // Create a scanner that performs real attestation requests to backend
        let realAttestationScanner = RealAttestationMockScanner()

        realAttestationScanner.scanCard { result in
            // Just pass through the real result - no mock data manipulation
            completion(result)
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
                        let response = AppScanTaskResponse(
                            card: mock.card,
                            walletData: mock.walletData,
                            primaryCard: nil
                        )

                        completion(.success(response))
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
                    case .realAttestation(let mock):
                        self.performRealAttestation(with: mock, completion: completion)
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
        case json(String)
        case realAttestation(CardMock)
    }

    enum Error: String, Swift.Error, LocalizedError {
        case jsonToDataError

        var errorDescription: String? {
            return rawValue
        }
    }
}
