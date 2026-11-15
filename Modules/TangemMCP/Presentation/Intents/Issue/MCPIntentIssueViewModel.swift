//
//  MCPIntentIssueViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import protocol Combine.ObservableObject
import struct Combine.Published
import enum TangemFoundation.FeedbackGenerator

@MainActor
final class MCPIntentIssueViewModel: ObservableObject, HashableObject {
    private let closeAction: () -> Void
    private let retryAction: () async -> Void
    private var retryTask: Task<Void, Never>?

    @Published private(set) var state: MCPIntentIssueState

    init(
        issue: MCPIntentIssue,
        closeAction: @escaping () -> Void,
        retryAction: @escaping () async -> Void
    ) {
        self.closeAction = closeAction
        self.retryAction = retryAction
        state = MCPIntentIssueState(issue: issue)
    }

    deinit {
        retryTask?.cancel()
    }

    func handle(action: MCPIntentIssueAction) {
        switch action {
        case .viewDidAppear:
            playIssueHaptic()

        case .navigationCloseButtonTapped:
            handleNavigationCloseButtonTapped()

        case .primaryButtonTapped:
            handlePrimaryButtonTapped()

        case .issueUpdated(let issue):
            state = MCPIntentIssueState(issue: issue)
            playIssueHaptic()
        }
    }

    private func playIssueHaptic() {
        switch state.issue.severity {
        case .notice:
            FeedbackGenerator.soft()

        case .error:
            FeedbackGenerator.error()
        }
    }

    private func handleNavigationCloseButtonTapped() {
        state.primaryButton.isLoading = false
        retryTask?.cancel()
        retryTask = nil
    }

    private func handlePrimaryButtonTapped() {
        guard state.issue.isRecoverable else {
            closeAction()
            return
        }

        guard retryTask == nil else {
            return
        }

        state.primaryButton.isLoading = true
        retryTask = Task { [weak self, retryAction] in
            await retryAction()
            self?.state.primaryButton.isLoading = false
            self?.retryTask = nil
        }
    }
}
