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
import TangemUIUtils
@testable import Tangem

@Suite("Tests for the joint operation details sheet following its operation")
@MainActor
struct JointAccountOperationDetailsViewModelTests {
    private let updates = PassthroughSubject<JointAccountOperationDetailsViewModel.Content, Never>()
    private let coordinator = RoutableSpy()
    private let provider = PendingOperationsProviderSpy()
    private let alertPresenter = AlertPresenterSpy()

    @Test("A new signature on the open operation reaches the sheet", .timeLimit(.minutes(1)))
    func newSignatureIsShown() async throws {
        let viewModel = makeViewModel()

        updates.send(makeContent(collectedSignaturesCount: 2))

        _ = try await viewModel.$content.first { $0.collectedSignaturesCount == 2 }.async()

        #expect(viewModel.content.collectedSignaturesCount == 2)
    }

    @Test("The signatures row counts the collected signatures against the threshold", .timeLimit(.minutes(1)))
    func signaturesRowCountsAgainstTheThreshold() async throws {
        let viewModel = makeViewModel()

        updates.send(makeContent(collectedSignaturesCount: 1, requiredSignaturesCount: 2, membersCount: 3))
        _ = try await viewModel.$content.first { $0.requiredSignaturesCount == 2 }.async()

        let row = try #require(signaturesRow(in: viewModel))
        #expect(row.title == Localization.jointOperationSignaturesProgress(1, 2))
        #expect(row.collectedCount == 1)
        #expect(row.requiredCount == 2)
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

        updates.send(makeContent(collectedSignaturesCount: 3, status: .sending))

        _ = try await viewModel.$content.first { $0.status == .sending }.async()

        #expect(viewModel.header.title == Localization.commonSending)
        #expect(signButton(in: viewModel) == nil)
        #expect(!viewModel.blocks.contains { if case .caption = $0 { true } else { false } })
    }

    @Test("An operation that has left the pending list is shown as sent", .timeLimit(.minutes(1)))
    func sentOperationIsShownAsSent() async throws {
        let viewModel = makeViewModel()
        let sentAt = Date(timeIntervalSince1970: 1_791_379_800)

        updates.send(makeContent(collectedSignaturesCount: 3, status: .sent(at: sentAt)))

        _ = try await viewModel.$content.first { if case .sent = $0.status { true } else { false } }.async()

        #expect(viewModel.header.title == Localization.commonSent)
        #expect(viewModel.header.date == TransactionDetailsFactory.headerDateFormatter.string(from: sentAt))
        #expect(signButton(in: viewModel) == nil)
        #expect(viewModel.blocks.contains { if case .caption(let text) = $0 { text == Localization.jointOperationSentFooter(3, 3) } else { false } })
    }

    @Test("The Sign button is confirmed the way the wallet signs")
    func signButtonFollowsTheSigner() {
        let cardButton = signButton(in: makeViewModel(signingActionButtonType: .cardTap))
        let holdButton = signButton(in: makeViewModel(signingActionButtonType: .holdToConfirm))

        #expect(cardButton?.signingType == .cardTap)
        #expect(holdButton?.signingType == .holdToConfirm)
    }

    @Test("The header menu copies the full recipient address")
    func headerMenuCopiesRecipient() {
        let actions = makeViewModel().header.menuSections.flatMap(\.actions).map(\.action)

        #expect(actions == [.copy(value: "0xrecipient", toast: Localization.walletNotificationAddressCopied, kind: .address)])
    }

    @Test("Tapping the recipient row copies the full address, the way the transaction details do")
    func recipientRowCopiesTheAddress() {
        let copyAction = makeViewModel().blocks.lazy.compactMap { block -> TransactionDetailsViewModel.ViewAction? in
            if case .counterparty(let data) = block { data.copyAction } else { nil }
        }.first

        #expect(copyAction == .copy(value: "0xrecipient", toast: Localization.walletNotificationAddressCopied, kind: .address))
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

        _ = try await alertPresenter.presentedAlertsCount.first { $0 > 0 }.async()

        #expect(alertPresenter.presentedAlertsCount.value == 1)
        withExtendedLifetime(viewModel) {}
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
        signingActionButtonType: SigningActionButtonViewType = .cardTap,
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
            signingActionButtonType: signingActionButtonType,
            content: makeContent(collectedSignaturesCount: 1),
            contentPublisher: updates.eraseToAnyPublisher(),
            pendingOperationsProvider: provider,
            coordinator: coordinator,
            alertPresenter: alertPresenter,
            sign: sign
        )
    }

    private func makeContent(
        collectedSignaturesCount: Int,
        requiredSignaturesCount: Int = 3,
        membersCount: Int = 3,
        signers: [JointAccountSignerRow.ViewData] = [],
        status: JointAccountOperationDetailsViewModel.Status = .awaitingSignatures
    ) -> JointAccountOperationDetailsViewModel.Content {
        JointAccountOperationDetailsViewModel.Content(
            collectedSignaturesCount: collectedSignaturesCount,
            requiredSignaturesCount: requiredSignaturesCount,
            membersCount: membersCount,
            signers: signers,
            answer: .awaiting,
            canSign: true,
            status: status
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

    private func signaturesRow(in viewModel: JointAccountOperationDetailsViewModel) -> TransactionDetailsSignaturesViewData? {
        viewModel.blocks.lazy.compactMap { block in
            if case .signatures(let data) = block { data } else { nil }
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

private final class AlertPresenterSpy: AlertPresenter {
    let presentedAlertsCount = CurrentValueSubject<Int, Never>(0)

    func present(alert: AlertBinder) {
        presentedAlertsCount.value += 1
    }

    func hideAlert() {}
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
