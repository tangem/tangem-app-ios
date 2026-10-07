//
//  JointAccountOperationDetailsViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import Testing
import TangemFoundation
import TangemLocalization
import TangemUI
@testable import Tangem

@Suite("Tests for the joint operation details sheet following its operation")
@MainActor
struct JointAccountOperationDetailsViewModelTests {
    private let updates = PassthroughSubject<JointAccountOperationDetailsViewModel.Content, Never>()
    private let coordinator = RoutableSpy()
    private let provider = PendingOperationsProviderSpy()

    @Test("A new signature on the open operation reaches the sheet", .timeLimit(.minutes(1)))
    func newSignatureIsShown() async throws {
        let viewModel = makeViewModel()

        updates.send(makeContent(collectedSignaturesCount: 2))

        _ = try await viewModel.$content.first { $0.collectedSignaturesCount == 2 }.async()

        #expect(viewModel.content.collectedSignaturesCount == 2)
    }

    @Test("An open signers screen follows the operation's signers and members", .timeLimit(.minutes(1)))
    func openSignersScreenIsUpdated() async throws {
        let viewModel = makeViewModel()
        viewModel.handleViewAction(.openSigners)

        guard case .signers(let signersViewModel) = viewModel.viewState else {
            Issue.record("The signers screen did not open")
            return
        }

        let signer = makeSigner(id: "0xsigner", answer: .signed(at: "12:00"))
        updates.send(makeContent(collectedSignaturesCount: 2, membersCount: 4, signers: [signer]))
        await drainMainQueue()

        #expect(signersViewModel.membersCount == 4)
        #expect(signersViewModel.signers.map(\.id) == ["0xsigner"])
    }

    @Test("The sheet stays open once this member has signed", .timeLimit(.minutes(1)))
    func ownSignatureKeepsTheSheetOpen() async throws {
        let viewModel = makeViewModel()
        viewModel.onAppear()

        viewModel.handleViewAction(.signOperation)

        _ = try await viewModel.$answer.first { $0 == .signed }.async()

        #expect(coordinator.closeCount.value == 0)
        #expect(provider.activeRequestsCount == 1)
    }

    @Test("Closing the sheet twice closes it once")
    func closingTwiceClosesOnce() {
        let viewModel = makeViewModel()
        viewModel.onAppear()

        viewModel.handleViewAction(.close)
        viewModel.handleViewAction(.close)

        #expect(coordinator.closeCount.value == 1)
        #expect(provider.activeRequestsCount == 0)
    }

    @Test("An operation being sent can no longer be signed", .timeLimit(.minutes(1)))
    func sendingOperationCannotBeSigned() async throws {
        let viewModel = makeViewModel()

        updates.send(makeContent(collectedSignaturesCount: 3, isSending: true))

        _ = try await viewModel.$content.first { $0.isSending }.async()

        #expect(viewModel.header.title == Localization.commonSending)
        #expect(signButton(in: viewModel)?.isEnabled == false)
        #expect(!viewModel.blocks.contains { if case .caption = $0 { true } else { false } })
    }

    @Test("The card icon on Sign is shown only to a wallet that signs with a card")
    func signIconFollowsTheSigner() {
        #expect(signButton(in: makeViewModel(hasNFCInteraction: true))?.icon != nil)
        #expect(signButton(in: makeViewModel(hasNFCInteraction: false))?.icon == nil)
    }

    @Test("The header menu copies the full recipient address")
    func headerMenuCopiesRecipient() {
        let actions = makeViewModel().header.menuSections.flatMap(\.actions).map(\.action)

        #expect(actions == [.copy(value: "0xrecipient", toast: Localization.walletNotificationAddressCopied, kind: .address)])
    }

    @Test("Frequent updates are held only while the sheet is on screen")
    func frequentUpdatesFollowVisibility() {
        let viewModel = makeViewModel()

        #expect(provider.activeRequestsCount == 0)

        viewModel.onAppear()
        #expect(provider.activeRequestsCount == 1)

        viewModel.onDisappear()
        #expect(provider.activeRequestsCount == 0)
    }

    @Test("A signature that fails tells the member so", .timeLimit(.minutes(1)))
    func failedSignatureShowsAnAlert() async throws {
        let viewModel = makeViewModel(sign: { throw JointOperationError.maliciousOperation })

        viewModel.handleViewAction(.signOperation)

        _ = try await viewModel.$alert.first { $0 != nil }.async()

        #expect(viewModel.alert != nil)
    }

    @Test("An operation Blockaid flags as malicious is named so, and nothing else is")
    func signingErrorAlertTellsMaliciousApart() {
        let malicious = JointAccountOperationSigningErrorAlert(error: JointOperationError.maliciousOperation)
        let unchecked = JointAccountOperationSigningErrorAlert(error: JointOperationError.securityCheckUnavailable)

        #expect(malicious.title == Localization.jointOperationMaliciousTitle)
        #expect(malicious.message == Localization.jointOperationMaliciousSubtitle)
        #expect(malicious.buttonText == Localization.commonClose)
        #expect(unchecked.title == Localization.commonSomethingWentWrong)
        #expect(unchecked.message == Localization.accountGenericErrorDialogMessage)
    }

    // MARK: - Helpers

    private func makeViewModel(
        hasNFCInteraction: Bool = true,
        sign: @escaping () async throws -> Void = {}
    ) -> JointAccountOperationDetailsViewModel {
        JointAccountOperationDetailsViewModel(
            tokenIconInfo: TokenIconInfo(
                name: "Ethereum",
                blockchainIconAsset: nil,
                imageURL: nil,
                isCustom: false,
                customTokenColor: nil
            ),
            cryptoAmount: "–0.1 ETH",
            fiatAmount: "$200",
            recipient: "0xrecipient",
            recipientBlockiesImage: nil,
            networkFee: "~0.0005 ETH",
            hasNFCInteraction: hasNFCInteraction,
            content: makeContent(collectedSignaturesCount: 1),
            contentPublisher: updates.eraseToAnyPublisher(),
            pendingOperationsProvider: provider,
            coordinator: coordinator,
            sign: sign
        )
    }

    private func makeContent(
        collectedSignaturesCount: Int,
        membersCount: Int = 3,
        signers: [JointAccountSignerRow.ViewData] = [],
        isSending: Bool = false
    ) -> JointAccountOperationDetailsViewModel.Content {
        JointAccountOperationDetailsViewModel.Content(
            collectedSignaturesCount: collectedSignaturesCount,
            requiredSignaturesCount: 3,
            membersCount: membersCount,
            signers: signers,
            answer: .awaiting,
            canSign: true,
            isSending: isSending
        )
    }

    private func makeSigner(id: String, answer: JointAccountSignerRow.Answer) -> JointAccountSignerRow.ViewData {
        JointAccountSignerRow.ViewData(
            id: id,
            icon: AddressBookContactNameIconViewData(letter: "A", color: .blue),
            name: "Alice",
            answer: answer
        )
    }

    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }

    private func signButton(in viewModel: JointAccountOperationDetailsViewModel) -> TransactionDetailsActionButtonViewData? {
        viewModel.blocks.lazy.compactMap { block in
            if case .action(let data) = block { data } else { nil }
        }.first
    }
}

// MARK: - Spies

private final class RoutableSpy: JointAccountOperationDetailsRoutable {
    let closeCount = CurrentValueSubject<Int, Never>(0)

    func closeOperationDetails() {
        closeCount.value += 1
    }
}

private final class PendingOperationsProviderSpy: JointAccountPendingOperationsProvider {
    private(set) var activeRequestsCount = 0

    var pendingOperations: [JointAccountPendingOperation] { [] }

    var pendingOperationsPublisher: AnyPublisher<[JointAccountPendingOperation], Never> {
        Empty().eraseToAnyPublisher()
    }

    func requestFrequentUpdates() -> AnyCancellable {
        activeRequestsCount += 1

        return AnyCancellable { [weak self] in
            self?.activeRequestsCount -= 1
        }
    }
}
