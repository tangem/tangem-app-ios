//
//  MCPIntentViewModelTests.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemAssets
@testable import TangemMCP

@MainActor
struct MCPIntentViewModelTests {
    @Test
    func sendIntentSheetTakesIntentId() {
        #expect(Self.makeSendIntentViewModel(spy: ActionSpy()).id == Self.intentId)
    }

    @Test
    func intentStatusSheetTakesIntentId() {
        #expect(Self.makeIntentStatusViewModel(spy: ActionSpy()).id == Self.intentId)
    }

    @Test
    func sendIntentCloseButtonRunsOnlyCloseAction() {
        let spy = ActionSpy()

        Self.makeSendIntentViewModel(spy: spy).handle(action: .closeButtonTapped)

        #expect(spy.actions == [.close])
    }

    @Test
    func sendIntentProceedButtonRunsOnlyProceedAction() {
        let spy = ActionSpy()

        Self.makeSendIntentViewModel(spy: spy).handle(action: .primaryButtonTapped)

        #expect(spy.actions == [.primary])
    }

    @Test
    func intentStatusCloseButtonRunsOnlyCloseAction() {
        let spy = ActionSpy()

        Self.makeIntentStatusViewModel(spy: spy).handle(action: .closeButtonTapped)

        #expect(spy.actions == [.close])
    }

    @Test
    func intentStatusPrimaryButtonRunsOnlyPrimaryAction() {
        let spy = ActionSpy()

        Self.makeIntentStatusViewModel(spy: spy).handle(action: .primaryButtonTapped)

        #expect(spy.actions == [.primary])
    }

    @Test
    func sendIntentViewModelIsReleasedAfterItsButtonsAreTapped() {
        var viewModel: MCPSendIntentViewModel? = Self.makeSendIntentViewModel(spy: ActionSpy())
        weak let releasedViewModel = viewModel

        viewModel?.handle(action: .closeButtonTapped)
        viewModel?.handle(action: .primaryButtonTapped)
        viewModel = nil

        #expect(releasedViewModel == nil)
    }

    @Test
    func intentStatusViewModelIsReleasedAfterItsButtonsAreTapped() {
        var viewModel: MCPIntentStatusViewModel? = Self.makeIntentStatusViewModel(spy: ActionSpy())
        weak let releasedViewModel = viewModel

        viewModel?.handle(action: .closeButtonTapped)
        viewModel?.handle(action: .primaryButtonTapped)
        viewModel = nil

        #expect(releasedViewModel == nil)
    }

    private static let intentId = "3f7c2a1e-9b4d-4c6a-8e21-5d0f7a9b1c33"

    private static func makeSendIntentViewModel(spy: ActionSpy) -> MCPSendIntentViewModel {
        MCPAssembly.ViewModels.makeSendIntent(
            id: intentId,
            agent: MCPAgent(id: "claude.ai", name: "Claude", host: "claude.ai", icon: nil),
            amount: "0.000001 ETH",
            token: MCPToken(
                displayName: "Ethereum",
                symbol: "ETH",
                network: MCPToken.Blockchain(iconAsset: Tokens.ethereumFill),
                kind: .nativeCoin(iconURL: URL(string: "https://example.com/ethereum.png")!)
            ),
            closeAction: { spy.actions.append(.close) },
            proceedAction: { spy.actions.append(.primary) }
        )
    }

    private static func makeIntentStatusViewModel(spy: ActionSpy) -> MCPIntentStatusViewModel {
        MCPAssembly.ViewModels.makeIntentStatus(
            id: intentId,
            status: .unreachable(canRetry: true),
            closeAction: { spy.actions.append(.close) },
            primaryAction: { spy.actions.append(.primary) }
        )
    }
}

@MainActor
private final class ActionSpy {
    enum Action: Equatable {
        case close
        case primary
    }

    var actions: [Action] = []
}
