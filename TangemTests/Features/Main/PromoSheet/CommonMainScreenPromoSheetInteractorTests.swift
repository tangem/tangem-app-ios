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

    @Test("A promo is recorded as shown only once its sheet appears, and only once")
    func recordsShownOnAppearance() {
        let originalShownIds = AppSettings.shared.shownMainScreenPromoSheetIds
        defer { AppSettings.shared.shownMainScreenPromoSheetIds = originalShownIds }
        AppSettings.shared.shownMainScreenPromoSheetIds = []

        let interactor = makeInteractor().interactor
        let appearance = PassthroughSubject<Void, Never>()
        var shownCount = 0

        interactor.markSheetShownOnAppearance(appearance.eraseToAnyPublisher(), managerId: "promo", onShown: { shownCount += 1 })

        #expect(!interactor.hasShownSheet(managerId: "promo"))

        appearance.send()
        appearance.send()

        #expect(interactor.hasShownSheet(managerId: "promo"))
        #expect(shownCount == 1)
        #expect(AppSettings.shared.shownMainScreenPromoSheetIds == ["promo"])
    }

    @Test("A sheet that goes away without appearing is not recorded as shown")
    func ignoresSheetThatNeverAppeared() {
        let interactor = makeInteractor().interactor
        let appearance = PassthroughSubject<Void, Never>()
        var shownCount = 0

        interactor.markSheetShownOnAppearance(appearance.eraseToAnyPublisher(), managerId: "unseen-promo", onShown: { shownCount += 1 })
        appearance.send(completion: .finished)

        #expect(!interactor.hasShownSheet(managerId: "unseen-promo"))
        #expect(shownCount == 0)
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
