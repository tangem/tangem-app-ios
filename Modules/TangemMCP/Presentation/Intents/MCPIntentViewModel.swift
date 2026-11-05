//
//  MCPIntentViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Combine
public import protocol TangemUI.FloatingSheetContentViewModel

@MainActor
public final class MCPIntentViewModel<IntentProposalState: Equatable>: ObservableObject, FloatingSheetContentViewModel {
    private let delegate: Delegate
    private var hasReportedAppearance = false
    private var hasReportedFlowTermination = false

    @Published private(set) var state: MCPIntentState<IntentProposalState>

    init(initialLoadingResult: MCPIntentLoadingResult<IntentProposalState>, delegate: Delegate) {
        self.delegate = delegate
        weak var futureSelf: MCPIntentViewModel<IntentProposalState>?
        state = Self.makeInitialState(initialLoadingResult: initialLoadingResult, owner: { futureSelf })
        futureSelf = self
    }

    isolated deinit {
        reportFlowTermination()
    }

    func handle(action: MCPIntentAction<IntentProposalState>) {
        switch action {
        case .viewDidAppear:
            reportAppearance()

        case .navigationCloseButtonTapped:
            handleNavigationCloseButtonTapped()

        case .issueTerminated:
            reportFlowTermination()

        case .issueRetryResultReceived(let loadingResult):
            handleLoadingResultUpdated(loadingResult)
        }
    }

    private func handleNavigationCloseButtonTapped() {
        if case .issue(let issueViewModel) = state {
            issueViewModel.handle(action: .navigationCloseButtonTapped)
        }
        reportFlowTermination()
    }

    private func handleLoadingResultUpdated(_ loadingResult: MCPIntentLoadingResult<IntentProposalState>) {
        guard case .issue(let issueViewModel) = state else {
            assertionFailure("Expected to be in issue state. Developer mistake.")
            return
        }

        switch loadingResult {
        case .issue(let issue):
            issueViewModel.handle(action: .issueUpdated(issue))

        case .proposal(let intentProposalState, let proceedAction):
            let proposalViewModel = MCPIntentProposalViewModel(proceedAction: proceedAction, state: intentProposalState)
            state = .proposal(proposalViewModel)
        }
    }

    private func reportAppearance() {
        guard !hasReportedAppearance else {
            return
        }

        hasReportedAppearance = true
        delegate.sheetAppeared()
    }

    private func reportFlowTermination() {
        guard !hasReportedFlowTermination else {
            return
        }

        hasReportedFlowTermination = true
        delegate.flowTerminated()
    }
}

extension MCPIntentViewModel {
    struct Delegate {
        let sheetAppeared: () -> Void
        let flowTerminated: () -> Void
        let issueRetryButtonTapped: () async -> MCPIntentLoadingResult<IntentProposalState>
    }
}

// MARK: - Factory methods

extension MCPIntentViewModel {
    private static func makeInitialState(
        initialLoadingResult: MCPIntentLoadingResult<IntentProposalState>,
        owner: @escaping () -> MCPIntentViewModel?
    ) -> MCPIntentState<IntentProposalState> {
        switch initialLoadingResult {
        case .issue(let issue):
            let issueViewModel = Self.makeIssueViewModel(issue: issue, owner: owner)
            return MCPIntentState.issue(issueViewModel)

        case .proposal(let intentProposalState, let proceedAction):
            let proposalViewModel = MCPIntentProposalViewModel(proceedAction: proceedAction, state: intentProposalState)
            return MCPIntentState.proposal(proposalViewModel)
        }
    }

    private static func makeIssueViewModel(
        issue: MCPIntentIssue,
        owner: @escaping () -> MCPIntentViewModel?
    ) -> MCPIntentIssueViewModel {
        MCPIntentIssueViewModel(
            issue: issue,
            closeAction: {
                owner()?.handle(action: .issueTerminated)
            },
            retryAction: {
                guard
                    let retryResult = await owner()?.delegate.issueRetryButtonTapped(),
                    !Task.isCancelled
                else {
                    return
                }

                owner()?.handle(action: .issueRetryResultReceived(retryResult))
            }
        )
    }
}
