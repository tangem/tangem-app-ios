//
//  RealAssetsFeaturedViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class RealAssetsFeaturedViewModel: ObservableObject {
    @Published private(set) var state: State = .loading

    @Injected(\.tangemApiService) private var apiService: TangemApiService

    private let categoryId: Int
    private let country: String?
    private let onTokenTap: (MarketsTokenModel) -> Void

    private let priceFormatter = MarketsTokenPriceFormatter()
    private let priceChangeUtility = PriceChangeUtility()

    private var loadingTask: Task<Void, Never>?
    private var bag = Set<AnyCancellable>()

    init(categoryId: Int, country: String?, onTokenTap: @escaping (MarketsTokenModel) -> Void) {
        self.categoryId = categoryId
        self.country = country
        self.onTokenTap = onTokenTap

        bindToCurrencyCodeUpdate()
        load()
    }

    deinit {
        loadingTask?.cancel()
    }

    func tryLoadAgain() {
        load()
    }
}

// MARK: - Loading

private extension RealAssetsFeaturedViewModel {
    func load() {
        loadingTask?.cancel()

        loadingTask = Task { @MainActor [weak self] in
            guard let self else { return }

            state = .loading

            do {
                let response = try await apiService.loadCoinsList(requestModel: makeRequestModel())
                state = .loaded(makeItems(from: response.tokens))
            } catch {
                guard !error.isCancellationError else { return }

                AppLogger.tag("Markets").error("Failed to load featured assets", error: error)
                state = .loaded([])
            }
        }
    }

    func makeRequestModel() -> MarketsDTO.General.Request {
        MarketsDTO.General.Request(
            currency: AppSettings.shared.selectedCurrencyCode,
            limit: Constants.limit,
            interval: Constants.interval,
            order: .category,
            search: nil,
            showNetworks: nil,
            categoryId: categoryId,
            country: country
        )
    }

    func makeItems(from tokens: [MarketsTokenModel]) -> [RealAssetsFeaturedItem] {
        tokens
            .filter { $0.restrictedForCountry != true }
            .map { token in
                RealAssetsFeaturedItem(
                    id: token.id,
                    name: token.name,
                    symbol: token.symbol.uppercased(),
                    imageURL: IconURLBuilder().tokenIconURL(id: token.id, size: .large),
                    price: priceFormatter.formatPrice(token.currentPrice),
                    priceChangeState: priceChangeUtility.convertToPriceChangeState(
                        changePercent: token.priceChangePercentage[Constants.interval.rawValue] ?? nil
                    ),
                    onTap: { [weak self] in
                        self?.onTokenTap(token)
                    }
                )
            }
    }

    func bindToCurrencyCodeUpdate() {
        AppSettings.shared.$selectedCurrencyCode
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.load()
            }
            .store(in: &bag)
    }
}

// MARK: - State

extension RealAssetsFeaturedViewModel {
    enum State {
        case loading
        case loaded([RealAssetsFeaturedItem])
    }
}

// MARK: - Constants

private extension RealAssetsFeaturedViewModel {
    enum Constants {
        static let limit = 20
        static let interval: MarketsPriceIntervalType = .day
    }
}
