//
//  CommonMainScreenPromoSheetInteractorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
@testable import Tangem

@Suite("CommonMainScreenPromoSheetInteractor")
struct CommonMainScreenPromoSheetInteractorTests {
    @Test("Only the first main screen appearance of the process is claimed")
    func claimsOnlyFirstAppearance() {
        let interactor = makeInteractor().interactor

        #expect(interactor.claimFirstMainScreenAppearance())
        #expect(!interactor.claimFirstMainScreenAppearance())
    }

    @Test(
        "A deeplink, an external link or a WalletConnect link marks the session as opened from a link",
        arguments: [
            IncomingAction.navigation(.support(SupportDeeplink())),
            .externalLink(URL(string: "https://tangem.com")!),
            .walletConnect(
                try! WalletConnectURLParser().parse(
                    uriString: "wc:8ad9144fec726c592b3bae26e2fa797e61b08d523fe9036ac7fe4f3c54b7b9f4@2?relay-protocol=irn&symKey=cc2f1426571a59111059b7661c6aecadc08784d299a2dce36c576844e40d6c81"
                )
            ),
        ]
    )
    func linkMarksSession(action: IncomingAction) {
        let (interactor, incomingActionManager) = makeInteractor()
        interactor.initialize()

        incomingActionManager.subject.send(action)

        #expect(interactor.presentationSettings.isOpenedFromLink)
    }

    @Test(
        "Actions that are not a link do not mark the session",
        arguments: [
            IncomingAction.start,
            .dismissSafari(URL(string: "https://tangem.com")!),
        ]
    )
    func nonLinkDoesNotMarkSession(action: IncomingAction) {
        let (interactor, incomingActionManager) = makeInteractor()
        interactor.initialize()

        incomingActionManager.subject.send(action)

        #expect(!interactor.presentationSettings.isOpenedFromLink)
    }

    private func makeInteractor() -> (interactor: CommonMainScreenPromoSheetInteractor, incomingActionManager: StubIncomingActionManager) {
        let incomingActionManager = StubIncomingActionManager()
        let interactor = CommonMainScreenPromoSheetInteractor(incomingActionManager: incomingActionManager)
        return (interactor, incomingActionManager)
    }
}

// MARK: - Stubs

private final class StubIncomingActionManager: IncomingActionManaging {
    let subject = PassthroughSubject<IncomingAction, Never>()

    var incomingActionsPublisher: AnyPublisher<IncomingAction, Never> {
        subject.eraseToAnyPublisher()
    }

    func becomeFirstResponder(_ responder: IncomingActionResponder) {}
    func resignFirstResponder(_ responder: IncomingActionResponder) {}
    func deliver(_ action: IncomingAction) {}
}
