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
    /// Currency the current `hotCryptoItemsSubject` prices are denominated in.
    private var loadedCurrencyCode: String?
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
                    requestModel: .init(currency: currencyCode)
                )

                guard !Task.isCancelled else { return }

                loadedCurrencyCode = currencyCode
                hotCryptoItemsSubject.send(fetchedHotCryptoItems.tokens)
            } catch {
                logLoadingError(error)
                dropItemsIfCurrencyMismatch(requestedCurrencyCode: currencyCode)
            }
        }
    }
}

// MARK: - Private

private extension CommonHotCryptoService {
    /// The list is rendered with the *currently selected* currency code, so items priced in a previous
    /// currency must not survive a failed reload for the new one.
    func dropItemsIfCurrencyMismatch(requestedCurrencyCode: String) {
        guard
            !Task.isCancelled,
            let loadedCurrencyCode,
            loadedCurrencyCode != requestedCurrencyCode
        else {
            return
        }

        self.loadedCurrencyCode = nil
        hotCryptoItemsSubject.send([])
    }

    func logLoadingError(_ error: Error) {
        switch error {
        case let error as TangemAPIError:
            ActionButtonsAnalyticsService.hotTokenError(errorCode: String(error.code.rawValue))
        case let error as MoyaError:
            ActionButtonsAnalyticsService.hotTokenError(errorCode: String(error.response?.statusCode ?? 999))
        default:
            ActionButtonsAnalyticsService.hotTokenError(errorCode: .unknown)
        }
    }
}
