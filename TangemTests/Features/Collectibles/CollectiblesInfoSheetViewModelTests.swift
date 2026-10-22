//
//  CollectiblesInfoSheetViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLocalization
import TangemTestKit
@testable import Tangem

@Suite("CollectiblesInfoSheetViewModel", .timeLimit(.minutes(1)))
@MainActor
final class CollectiblesInfoSheetViewModelTests: LeakTrackingTestSuite {
    typealias SUT = CollectiblesInfoSheetViewModel

    @Test("Presenting shows the sheet with the latest model", .enabled(if: Self.isSystemSheetAvailable))
    func presentsLatestModel() {
        let (sut, _) = makeSUT()

        sut.present(with: .packUnopened(openPack: {}))

        #expect(sut.isPresented)
        #expect(sut.model.title == Localization.collectiblesPackUnopenedTitle)
    }

    @Test(
        "A button runs its action once the sheet has been dismissed",
        .enabled(if: Self.isSystemSheetAvailable),
        arguments: SheetButton.allCases
    )
    func actionRunsAfterDismiss(button: SheetButton) {
        let (sut, actions) = makeSUT()
        sut.present()

        tap(button, on: sut)

        #expect(!sut.isPresented)
        #expect(actions.totalCallsCount == 0)

        sut.didDismiss()

        #expect(actions.callsCount(of: button) == 1)
        #expect(actions.totalCallsCount == 1)
    }

    @Test(
        "Immediate timing runs the action on the tap and not again on dismiss",
        .enabled(if: Self.isSystemSheetAvailable)
    )
    func immediateActionRunsOnTap() {
        let (sut, actions) = makeSUT(actionTiming: .immediately)
        sut.present()

        sut.primary()

        #expect(!sut.isPresented)
        #expect(actions.primaryCallsCount == 1)

        sut.didDismiss()

        #expect(actions.primaryCallsCount == 1)
    }

    @Test("A second tap while the sheet is dismissing is ignored", .enabled(if: Self.isSystemSheetAvailable))
    func secondTapWhileDismissingIsIgnored() {
        let (sut, actions) = makeSUT()
        sut.present()

        sut.primary()
        sut.secondary()
        sut.didDismiss()

        #expect(actions.primaryCallsCount == 1)
        #expect(actions.secondaryCallsCount == 0)
    }

    @Test("Closing drops the sheet without running any action", .enabled(if: Self.isSystemSheetAvailable))
    func closeRunsNothing() {
        let (sut, actions) = makeSUT()
        sut.present()

        sut.close()
        sut.primary()
        sut.didDismiss()

        #expect(!sut.isPresented)
        #expect(actions.totalCallsCount == 0)
    }

    @Test("A dismissed sheet can be presented and used again", .enabled(if: Self.isSystemSheetAvailable))
    func presentsAgainAfterDismiss() {
        let (sut, actions) = makeSUT()
        sut.present()
        sut.close()
        sut.didDismiss()

        sut.present()
        #expect(sut.isPresented)

        sut.primary()
        sut.didDismiss()

        #expect(actions.primaryCallsCount == 1)
    }

    @Test(
        "A sheet without a secondary button just closes on the secondary tap",
        .enabled(if: Self.isSystemSheetAvailable)
    )
    func missingSecondaryButtonCloses() {
        let (sut, actions) = makeSUT(hasSecondaryButton: false)
        sut.present()

        sut.secondary()
        sut.didDismiss()

        #expect(!sut.isPresented)
        #expect(actions.totalCallsCount == 0)
    }
}

// MARK: - Arguments

extension CollectiblesInfoSheetViewModelTests {
    enum SheetButton: CaseIterable, Sendable {
        case primary
        case secondary
    }

    nonisolated static let isSystemSheetAvailable = ProcessInfo.processInfo.isOperatingSystemAtLeast(
        OperatingSystemVersion(majorVersion: 26, minorVersion: 0, patchVersion: 0)
    )
}

// MARK: - Helpers

private extension CollectiblesInfoSheetViewModelTests {
    func makeSUT(
        actionTiming: SUT.ActionTiming = .afterDismiss,
        hasSecondaryButton: Bool = true
    ) -> (SUT, ActionSpy) {
        let actions = ActionSpy()
        let model = makeModel(hasSecondaryButton: hasSecondaryButton, actions: actions)
        let sut = SUT(model: model, actionTiming: actionTiming)
        return (trackForMemoryLeaks(sut), actions)
    }

    func makeModel(hasSecondaryButton: Bool, actions: ActionSpy) -> CollectiblesInfoSheetView.Model {
        guard hasSecondaryButton else {
            return .packUnopened(openPack: { actions.primaryCallsCount += 1 })
        }

        return .lowInventory(
            explorePacks: { actions.primaryCallsCount += 1 },
            enableTurboMode: { actions.secondaryCallsCount += 1 }
        )
    }

    func tap(_ button: SheetButton, on sut: SUT) {
        switch button {
        case .primary: sut.primary()
        case .secondary: sut.secondary()
        }
    }
}

// MARK: - Spies

@MainActor
private final class ActionSpy {
    var primaryCallsCount = 0
    var secondaryCallsCount = 0

    var totalCallsCount: Int {
        primaryCallsCount + secondaryCallsCount
    }

    func callsCount(of button: CollectiblesInfoSheetViewModelTests.SheetButton) -> Int {
        switch button {
        case .primary: primaryCallsCount
        case .secondary: secondaryCallsCount
        }
    }
}
