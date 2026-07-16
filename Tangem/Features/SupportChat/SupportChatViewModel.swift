//
//  SupportChatViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class SupportChatViewModel: ObservableObject, Identifiable {
    let widgetHTML: String

    /// Emits a JS snippet that injects the log zip into the widget's file input.
    let injectJSPublisher = PassthroughSubject<String, Never>()

    /// Emits when the WebView should reload the widget (chat failed to render in time).
    let reloadPublisher = PassthroughSubject<Void, Never>()

    @Published private(set) var isSendingLogs = false
    @Published private(set) var loadState: LoadingResult<Void, Error> = .loading

    private let logsComposer: LogsComposer
    private let tokenStorage = SupportChatTokenStorage()
    private let analyticsSource: Analytics.SupportChatSource
    private var loadTimeoutTask: Task<Void, Never>?
    private var reloadAttempts = 0

    init(input: SupportChatInputModel) {
        logsComposer = input.logsComposer
        analyticsSource = input.source
        widgetHTML = SupportChatHTMLBuilder.makeWidgetHTML(
            userIdentifier: input.userIdentifier,
            savedToken: tokenStorage.loadValidToken(),
            initialMessage: input.initialMessage
        )
        scheduleLoadTimeout()
    }

    func markChatReady() {
        loadTimeoutTask?.cancel()
        loadTimeoutTask = nil
        guard !loadState.isSuccess else { return }
        loadState = .success(())
        Analytics.log(.supportChatScreenOpened, params: [.source: analyticsSource.parameterValue])
    }

    func onClose() {
        Analytics.log(.supportChatScreenClosed)
    }

    func saveSessionToken(_ token: String) {
        tokenStorage.save(token: token)
    }

    func sendLogs() {
        guard !isSendingLogs else { return }
        isSendingLogs = true

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { isSendingLogs = false }

            guard let archive = await loadLogsArchive() else { return }

            // base64 of a potentially large archive — encode off the main actor.
            let script = await Task.detached {
                SupportChatHTMLBuilder.makeInjectScript(
                    base64: archive.data.base64EncodedString(),
                    fileName: archive.file.lastPathComponent
                )
            }.value

            injectJSPublisher.send(script)
        }
    }

    private func scheduleLoadTimeout() {
        loadTimeoutTask?.cancel()
        loadTimeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Constants.loadTimeout))
            guard !Task.isCancelled else { return }
            self?.handleLoadTimeout()
        }
    }

    private func handleLoadTimeout() {
        guard loadState.isLoading else { return }

        if reloadAttempts < Constants.maxReloadAttempts {
            reloadAttempts += 1
            reloadPublisher.send()
            scheduleLoadTimeout()
        } else {
            loadState = .failure(SupportChatError.failedToLoad)
            Analytics.log(.supportChatScreenError)
        }
    }

    private func loadLogsArchive() async -> (data: Data, file: URL)? {
        await withCheckedContinuation { continuation in
            logsComposer.getLogsArchive { continuation.resume(returning: $0) }
        }
    }
}

// MARK: - Constants

private extension SupportChatViewModel {
    enum Constants {
        static let loadTimeout: TimeInterval = 15
        static let maxReloadAttempts = 3
    }
}

// MARK: - Error

extension SupportChatViewModel {
    enum SupportChatError: Error {
        case failedToLoad
    }
}
