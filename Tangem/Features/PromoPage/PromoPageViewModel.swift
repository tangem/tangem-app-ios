//
//  PromoPageViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

@MainActor
final class PromoPageViewModel: ObservableObject {
    let url: URL

    @Published private(set) var isLoading = true

    private let dismiss: @MainActor () -> Void
    private let waitForLoadTimeout: @Sendable () async throws -> Void
    private let urlValidator = PromoPageURLValidator()

    private var loadTimeoutTask: Task<Void, Never>?
    private var isDismissed = false

    init(
        url: URL,
        dismiss: @escaping @MainActor () -> Void,
        waitForLoadTimeout: @escaping @Sendable () async throws -> Void = { try await Task.sleep(for: .seconds(Constants.loadTimeout)) }
    ) {
        self.url = url
        self.dismiss = dismiss
        self.waitForLoadTimeout = waitForLoadTimeout
    }
}

// MARK: - View events

extension PromoPageViewModel {
    func onAppear() {
        guard isLoading, !isDismissed, loadTimeoutTask == nil else {
            return
        }

        loadTimeoutTask = Task { [weak self, waitForLoadTimeout] in
            do {
                try await waitForLoadTimeout()
            } catch {
                return
            }

            guard !Task.isCancelled else {
                return
            }

            self?.pageDidFailLoading()
        }
    }

    func onDisappear() {
        isDismissed = true
        cancelLoadTimeout()
    }

    func pageDidFinishLoading() {
        guard isLoading else {
            return
        }

        isLoading = false
        cancelLoadTimeout()
    }

    func pageDidFailLoading() {
        guard isLoading, !isDismissed else {
            return
        }

        isDismissed = true
        cancelLoadTimeout()
        dismiss()
    }

    func allowsNavigation(to url: URL) -> Bool {
        urlValidator.isAllowed(url)
    }
}

// MARK: - Private

private extension PromoPageViewModel {
    func cancelLoadTimeout() {
        loadTimeoutTask?.cancel()
        loadTimeoutTask = nil
    }
}

// MARK: - Constants

private extension PromoPageViewModel {
    enum Constants {
        static let loadTimeout: TimeInterval = 15
    }
}
