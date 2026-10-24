//
//  MarketsTokenDetailsExchangesListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class MarketsTokenDetailsExchangesListViewModel: ObservableObject {
    @Published var exchangesList: LoadingResult<[MarketsTokenDetailsExchangeItemInfo], any Error> = .loading
    var isMarketsSheetStyle: Bool { presentationStyle == .marketsSheet }
    let numberOfExchangesListedOn: Int
    let onBackButtonAction: () -> Void

    private let exchangesListLoader: MarketsTokenExchangesListLoader
    private let tokenId: String
    private let presentationStyle: MarketsTokenDetailsPresentationStyle

    private let exchangesListMinReloadInterval: TimeInterval = 10.0

    private var loadingCancellable: AnyCancellable?
    private var lastLoadAttemptDate: Date?

    init(
        tokenId: String,
        numberOfExchangesListedOn: Int,
        presentationStyle: MarketsTokenDetailsPresentationStyle,
        exchangesListLoader: MarketsTokenExchangesListLoader,
        onBackButtonAction: @escaping () -> Void
    ) {
        self.tokenId = tokenId
        self.numberOfExchangesListedOn = numberOfExchangesListedOn
        self.presentationStyle = presentationStyle
        self.exchangesListLoader = exchangesListLoader
        self.onBackButtonAction = onBackButtonAction
    }

    func reloadExchangesList() {
        exchangesList = .loading
        loadExchangesList()
    }
}

extension MarketsTokenDetailsExchangesListViewModel {
    func loadExchangesList() {
        guard loadingCancellable == nil else {
            return
        }

        let date = Date()
        let remainingTime: TimeInterval
        if let lastLoadAttemptDate {
            remainingTime = max(exchangesListMinReloadInterval - date.timeIntervalSince(lastLoadAttemptDate), 0)
        } else {
            remainingTime = 0
        }
        loadingCancellable = Task.delayed(withDelay: remainingTime) { [weak self] in
            do {
                guard let self else {
                    return
                }

                let response = try await exchangesListLoader.loadExchangesList(for: tokenId)
                await handleLoadResult(.success(response))
            } catch {
                await self?.handleLoadResult(.failure(error))
            }
        }.eraseToAnyCancellable()
    }
}

private extension MarketsTokenDetailsExchangesListViewModel {
    @MainActor
    func handleLoadResult(_ result: Result<[MarketsTokenDetailsExchangeItemInfo], any Error>) async {
        lastLoadAttemptDate = Date()
        do {
            let list = try result.get()

            exchangesList = .success(list)
        } catch {
            if error.isCancellationError {
                return
            }

            exchangesList = .failure(error)
        }

        loadingCancellable = nil
    }
}
