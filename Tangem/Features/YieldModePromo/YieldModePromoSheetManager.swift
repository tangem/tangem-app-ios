//
//  YieldModePromoSheetManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class YieldModePromoSheetManager {
    private let catalogProvider: YieldModePromoCatalogProvider
    private let makePositionsProvider: () -> YieldModePromoPositionsProvider?
    private let earnOffersLoader: YieldModePromoEarnOffersLoader
    private let analyticsLogger: YieldModePromoAnalyticsLogger
    private let candidateResolver = YieldModePromoCandidateResolver()
    private weak var routable: YieldModePromoSheetRoutable?

    private var content: YieldModePromoContent?

    init(
        catalogProvider: YieldModePromoCatalogProvider,
        makePositionsProvider: @escaping () -> YieldModePromoPositionsProvider?,
        earnOffersLoader: YieldModePromoEarnOffersLoader,
        analyticsLogger: YieldModePromoAnalyticsLogger,
        routable: YieldModePromoSheetRoutable?
    ) {
        self.catalogProvider = catalogProvider
        self.makePositionsProvider = makePositionsProvider
        self.earnOffersLoader = earnOffersLoader
        self.analyticsLogger = analyticsLogger
        self.routable = routable
    }

    private func resolve(catalog: YieldModePromoCatalog, positions: [YieldModePromoPosition]) -> Resolution? {
        switch catalog.loadState {
        case .idle, .loading:
            return nil
        case .failed:
            return .unavailable(.dataNotReady)
        case .loaded:
            break
        }

        switch candidateResolver.resolve(positions: positions, markets: catalog.markets) {
        case .waiting:
            return nil
        case .noEligibleToken:
            return .unavailable(.noEligibleContent)
        case .dataNotReady:
            return .unavailable(.dataNotReady)
        case .candidate(let candidate):
            return .candidate(candidate)
        }
    }

    private static func evaluate(
        candidate: YieldModePromoCandidateResolver.Candidate,
        earnOffers: Result<EarnDTO.List.Response, Error>
    ) -> Evaluation {
        guard case .success(let earnResponse) = earnOffers else {
            return Evaluation(state: .unavailable(.dataNotReady), content: nil)
        }

        guard earnResponse.meta.total > 0 else {
            return Evaluation(state: .unavailable(.noEligibleContent), content: nil)
        }

        guard let content = YieldModePromoContent(candidate: candidate, earnResponse: earnResponse) else {
            return Evaluation(state: .unavailable(.dataNotReady), content: nil)
        }

        return Evaluation(state: .ready, content: content)
    }
}

// MARK: - Resolution

private extension YieldModePromoSheetManager {
    enum Resolution {
        case unavailable(MainScreenPromoSheetSkipReason)
        case candidate(YieldModePromoCandidateResolver.Candidate)
    }

    struct Evaluation {
        let state: MainScreenPromoSheetManagerState
        let content: YieldModePromoContent?
    }
}

// MARK: - MainScreenPromoSheetManager

extension YieldModePromoSheetManager: MainScreenPromoSheetManager {
    var id: String {
        "yield_mode_promo"
    }

    var experimentKey: ExperimentFeatureFlagKey {
        .yieldModePromo
    }

    var statePublisher: AnyPublisher<MainScreenPromoSheetManagerState, Never> {
        guard let positionsProvider = makePositionsProvider() else {
            return Just(.unavailable(.noEligibleContent)).eraseToAnyPublisher()
        }

        return Publishers.CombineLatest(
            catalogProvider.catalogPublisher,
            positionsProvider.positionsPublisher
        )
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .compactMap { manager, input in
            manager.resolve(catalog: input.0, positions: input.1)
        }
        .first()
        .flatMap { [earnOffersLoader] resolution -> AnyPublisher<Evaluation, Never> in
            switch resolution {
            case .unavailable(let reason):
                return Just(Evaluation(state: .unavailable(reason), content: nil)).eraseToAnyPublisher()
            case .candidate(let candidate):
                return Deferred {
                    Future.async { try await earnOffersLoader.loadYieldOffers() }
                }
                .map(Result<EarnDTO.List.Response, Error>.success)
                .catch { Just(.failure($0)) }
                .map { Self.evaluate(candidate: candidate, earnOffers: $0) }
                .receiveOnMain()
                .eraseToAnyPublisher()
            }
        }
        .handleEvents(receiveOutput: { [weak self] evaluation in
            self?.content = evaluation.content
        })
        .map { $0.state }
        .eraseToAnyPublisher()
    }

    func canHandlePresentation(_ settings: MainScreenPromoSheetPresentationSettings) -> Bool {
        !settings.isOpenedFromLink
    }

    func presentSheet(experimentVariant: String?) -> AnyPublisher<Void, Never>? {
        guard let content, let routable else {
            return nil
        }

        let data = content.candidateData

        return MainActor.assumeIsolated {
            let viewModel = YieldModePromoSheetViewModel(data: data, routable: routable, analyticsLogger: analyticsLogger)
            routable.presentYieldModePromo(viewModel)
            return viewModel.appearancePublisher
        }
    }

    func logShown() {}

    func logSkipped(_ reason: MainScreenPromoSheetSkipReason) {}
}

// MARK: - Factory

extension YieldModePromoSheetManager {
    static func make(routable: YieldModePromoSheetRoutable) -> YieldModePromoSheetManager? {
        guard FeatureProvider.isAvailable(.yieldModePromo) else {
            return nil
        }

        return YieldModePromoSheetManager(
            catalogProvider: CommonYieldModePromoCatalogProvider(),
            makePositionsProvider: {
                InjectedValues[\.userWalletRepository].selectedModel.map(CommonYieldModePromoPositionsProvider.init)
            },
            earnOffersLoader: CommonYieldModePromoEarnOffersLoader(),
            analyticsLogger: CommonYieldModePromoAnalyticsLogger(),
            routable: routable
        )
    }
}
