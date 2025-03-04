//
//  HotCryptoService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import enum Moya.MoyaError

protocol HotCryptoService: AnyObject {
    var hotCryptoItemsPublisher: AnyPublisher<[HotCryptoDTO.Response.HotToken], Never> { get }

    func loadHotCrypto(_ currencyCode: String)
}

final class CommonHotCryptoService {
    // MARK: - Dependencies

    @Injected(\.tangemApiService)
    private var tangemApiService: TangemApiService

    // MARK: - Private properties

    private var hotCryptoItemsSubject = CurrentValueSubject<[HotCryptoDTO.Response.HotToken], Never>([])
    private var currencyCodeBag: AnyCancellable?
    private var loadTask: Task<Void, Never>?

    init() {
        bind()
    }

    func bind() {
        currencyCodeBag = AppSettings.shared.$selectedCurrencyCode
            .dropFirst()
            .withWeakCaptureOf(self)
            .receiveValue { service, currencyCode in
                service.loadHotCrypto(currencyCode)
            }
    }
}

// MARK: - HotCryptoService

extension CommonHotCryptoService: HotCryptoService {
    var hotCryptoItemsPublisher: AnyPublisher<[HotCryptoDTO.Response.HotToken], Never> {
        hotCryptoItemsSubject.eraseToAnyPublisher()
    }

    func loadHotCrypto(_ currencyCode: String) {
        loadTask?.cancel()

        loadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let fetchedHotCryptoItems = try await tangemApiService.loadHotCrypto(
                    requestModel: .init(currency: AppSettings.shared.selectedCurrencyCode)
                )

                guard !Task.isCancelled else { return }

                hotCryptoItemsSubject.send(fetchedHotCryptoItems.tokens)
            } catch let error as TangemAPIError {
                ActionButtonsAnalyticsService.hotTokenError(errorCode: String(error.code.rawValue))
            } catch let error as MoyaError {
                ActionButtonsAnalyticsService.hotTokenError(errorCode: String(error.response?.statusCode ?? 999))
            } catch {
                ActionButtonsAnalyticsService.hotTokenError(errorCode: .unknown)
            }
        }
    }
}
