//
//  HotCryptoService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

protocol HotCryptoService: AnyObject {
    var hotCryptoItemsPublisher: AnyPublisher<[HotCryptoToken], Never> { get }

    func loadHotCrypto(_ currencyCode: String)
}

final class CommonHotCryptoService {
    // MARK: - Dependencies

    @Injected(\.tangemApiService)
    private var tangemApiService: TangemApiService

    // MARK: - Private properties

    private var hotCryptoItemsSubject = CurrentValueSubject<[HotCryptoToken], Never>([])
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
    var hotCryptoItemsPublisher: AnyPublisher<[HotCryptoToken], Never> {
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

                let tokenMapper = TokenItemMapper(supportedBlockchains: Blockchain.allMainnetCases.toSet())

                hotCryptoItemsSubject.send(
                    fetchedHotCryptoItems.tokens.map {
                        .init(from: $0, tokenMapper: tokenMapper, imageHost: nil)
                    }
                )
            } catch let error as TangemAPIError {
                ActionButtonsAnalyticsService.hotTokenError(errorCode: error.code.description ?? "")
            } catch {
                ActionButtonsAnalyticsService.hotTokenError(errorCode: .unknown)
            }
        }
    }
}
