//
//  SendAmountExternalUpdaterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import Testing
import TangemTestKit
@testable import Tangem

@Suite("SendAmountExternalUpdater")
final class SendAmountExternalUpdaterTests: LeakTrackingTestSuite {
    // MARK: - Weak References Test

    @Test("Does not retain dependencies - uses weak references")
    func doesNotRetainDependencies() async {
        var viewModel: SendAmountExternalUpdatableViewModelMock? = .init()
        var interactor: SendAmountInteractorMock? = .init()

        let sut = SendAmountExternalUpdater(viewModel: viewModel!, interactor: interactor!)

        weak var weakViewModel: SendAmountExternalUpdatableViewModelMock?
        weak var weakInteractor: SendAmountInteractorMock?
        weakViewModel = viewModel
        weakInteractor = interactor

        viewModel = nil
        interactor = nil

        #expect(weakViewModel == nil, "ViewModel should be deallocated - updater should use weak reference")
        #expect(weakInteractor == nil, "Interactor should be deallocated - updater should use weak reference")

        _ = sut
    }

    @Test("Updater correctly calls viewModel and interactor")
    func updaterCallsDependencies() async {
        let (sut, viewModel, interactor) = makeSUT()

        sut.externalUpdate(amount: 100)

        #expect(interactor.updateSourceAmountCalls.count == 1)
        #expect(interactor.updateSourceAmountCalls.first == 100)
        #expect(viewModel.externalUpdateCalls.count == 1)
    }

    @Test("Updater handles nil amount")
    func updaterHandlesNilAmount() async {
        let (sut, _, interactor) = makeSUT()

        sut.externalUpdate(amount: nil)

        #expect(interactor.updateSourceAmountCalls.count == 1)
        #expect(interactor.updateSourceAmountCalls[0] == nil)
    }

    @Test("Updater routes crypto amount to the crypto-explicit interactor method")
    func updaterRoutesCryptoAmount() async {
        let (sut, viewModel, interactor) = makeSUT()

        sut.externalUpdate(cryptoAmount: 100)

        #expect(interactor.updateSourceCryptoAmountCalls.count == 1)
        #expect(interactor.updateSourceCryptoAmountCalls.first == 100)
        #expect(interactor.updateSourceAmountCalls.isEmpty)
        #expect(viewModel.externalUpdateCalls.count == 1)
    }
}

private extension SendAmountExternalUpdaterTests {
    // MARK: - Helpers

    func makeSUT() -> (
        sut: SendAmountExternalUpdater,
        viewModel: SendAmountExternalUpdatableViewModelMock,
        interactor: SendAmountInteractorMock
    ) {
        let viewModel = trackForMemoryLeaks(SendAmountExternalUpdatableViewModelMock())
        let interactor = trackForMemoryLeaks(SendAmountInteractorMock())
        let sut = SendAmountExternalUpdater(viewModel: viewModel, interactor: interactor)
        return (sut, viewModel, interactor)
    }
}
