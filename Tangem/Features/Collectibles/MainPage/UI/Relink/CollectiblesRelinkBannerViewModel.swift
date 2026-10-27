//
//  CollectiblesRelinkBannerViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemCollectibles
import TangemFoundation

@MainActor
final class CollectiblesRelinkBannerViewModel: ObservableObject {
    // MARK: - Properties

    private let relinker: any CollectiblesRelinkStatusProvider & CollectiblesOnboarder
    private let openReconnection: (@MainActor () -> Void)?

    private var errorDismissTask: Task<Void, Error>?

    // MARK: - Publishers

    @Published private(set) var isVisible = false
    @Published private(set) var isRelinking = false
    @Published private(set) var errorMessage: String?

    // MARK: - Init

    init(
        relinker: any CollectiblesRelinkStatusProvider & CollectiblesOnboarder,
        openReconnection: (@MainActor () -> Void)?
    ) {
        self.relinker = relinker
        self.openReconnection = openReconnection

        relinker.isRelinkRequiredPublisher
            .receiveOnMain()
            .assign(to: &$isVisible)

        relinker.isRelinkingPublisher
            .receiveOnMain()
            .assign(to: &$isRelinking)
    }

    // MARK: - Methods

    func relink() {
        guard !isRelinking else {
            return
        }

        CollectiblesLogger.debug("relink: Relink account button tapped")

        guard let openReconnection else {
            signRelink()
            return
        }

        openReconnection()
    }

    func dismissError() {
        errorDismissTask?.cancel()
        errorDismissTask = nil
        errorMessage = nil
    }
}

// MARK: - Private logic

private extension CollectiblesRelinkBannerViewModel {
    func signRelink() {
        Task { [weak self, relinker] in
            do {
                try await relinker.onboard()
            } catch {
                guard !error.isCancellationError else {
                    CollectiblesLogger.debug("relink: cancelled")
                    return
                }

                CollectiblesLogger.debug("relink: failed: \(error)")
                self?.showError()
            }
        }
    }

    // [REDACTED_TODO_COMMENT]
    func showError() {
        errorMessage = "Something went wrong. Try again"

        errorDismissTask?.cancel()
        errorDismissTask = Task { [weak self] in
            try await Task.sleep(for: Constants.errorDisplayDuration)
            self?.errorMessage = nil
            self?.errorDismissTask = nil
        }
    }
}

// MARK: - Constants

private extension CollectiblesRelinkBannerViewModel {
    enum Constants {
        static let errorDisplayDuration: Duration = .seconds(3)
    }
}
