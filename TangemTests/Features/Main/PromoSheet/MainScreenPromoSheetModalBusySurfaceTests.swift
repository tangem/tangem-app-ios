//
//  MainScreenPromoSheetModalBusySurfaceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Testing
@testable import Tangem

@Suite("Promo sheet busy surface for main screen modals")
struct MainScreenPromoSheetModalBusySurfaceTests {
    @Test("A modal already on screen makes the main screen busy")
    func presentedModalIsBusy() {
        #expect(busyValues(isPresented: true, slotChanges: []) == [true])
    }

    @Test("Opening a modal makes the main screen busy")
    func openingModalIsBusy() {
        #expect(busyValues(isPresented: false, slotChanges: [true]) == [false, true])
    }

    @Test("A modal opened and closed again keeps the main screen busy while it animates out")
    func closedModalStaysBusy() {
        #expect(busyValues(isPresented: false, slotChanges: [true, false]) == [false, true])
    }

    @Test("Clearing an empty slot leaves the main screen free")
    func clearingEmptySlotIsNotBusy() {
        #expect(busyValues(isPresented: false, slotChanges: [false, false]) == [false])
    }
}

// MARK: - Helpers

private extension MainScreenPromoSheetModalBusySurfaceTests {
    func busyValues(isPresented: Bool, slotChanges: [Bool]) -> [Bool] {
        let slot = CurrentValueSubject<Bool, Never>(isPresented)
        var values: [Bool] = []

        let cancellable = MainScreenPromoSheetModalBusySurface.publisher(isModalPresented: isPresented, modalPresences: [slot.eraseToAnyPublisher()])
            .sink { values.append($0) }
        slotChanges.forEach(slot.send)
        cancellable.cancel()

        return values
    }
}
