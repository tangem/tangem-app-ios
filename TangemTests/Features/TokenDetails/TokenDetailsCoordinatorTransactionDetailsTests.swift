//
//  TokenDetailsCoordinatorTransactionDetailsTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@MainActor
@Suite("TokenDetailsCoordinator transaction details presentation", .serialized)
struct TokenDetailsCoordinatorTransactionDetailsTests {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.floatingSheetPresentingStateProvider) private var sheetStateProvider: any FloatingSheetPresentingStateProvider

    private static let presentationPreparationLimit: Duration = .seconds(1.5)

    @Test("Opening the details again while they are shown queues no second sheet", .timeLimit(.minutes(1)))
    func repeatedOpenWhileShownQueuesNoSecondSheet() async throws {
        try await withSheetsDisplayed {
            let coordinator = TokenDetailsCoordinator(dismissAction: { _ in }, popToRootAction: { _ in })
            let routeData = makeRouteData()

            coordinator.openTransactionDetails(routeData)
            _ = await sheetStateProvider.hasPresentedSheetPublisher.values.first { $0 }

            coordinator.openTransactionDetails(routeData)
            try await Task.sleep(for: Self.presentationPreparationLimit)

            floatingSheetPresenter.removeActiveSheet()

            #expect(!sheetStateProvider.hasPresentedSheet, "Closing the details revealed a duplicate sheet queued behind them")
        }
    }

    @Test("Another sheet on screen queues the details behind it instead of dropping them", .timeLimit(.minutes(1)))
    func openWhileAnotherSheetIsShownQueuesTheDetails() async throws {
        try await withSheetsDisplayed {
            let walletConnectSheet = makeWalletConnectSheet()
            floatingSheetPresenter.enqueue(sheet: walletConnectSheet)

            let coordinator = TokenDetailsCoordinator(dismissAction: { _ in }, popToRootAction: { _ in })

            coordinator.openTransactionDetails(makeRouteData())
            try await Task.sleep(for: Self.presentationPreparationLimit)

            floatingSheetPresenter.removeSheet(withId: walletConnectSheet.id)

            #expect(sheetStateProvider.hasPresentedSheet, "The details were dropped because another sheet was on screen")
        }
    }
}

// MARK: - Helpers

private extension TokenDetailsCoordinatorTransactionDetailsTests {
    func withSheetsDisplayed(_ body: () async throws -> Void) async throws {
        floatingSheetPresenter.resumeSheetsDisplaying()
        defer {
            floatingSheetPresenter.removeAllSheets()
            floatingSheetPresenter.pauseSheetsDisplaying()
        }

        try await body()
    }

    func makeWalletConnectSheet() -> WalletConnectErrorViewModel {
        WalletConnectErrorViewModel(
            state: WalletConnectErrorViewState(
                icon: .walletConnect,
                title: "Connection timed out",
                subtitle: "Try again",
                buttonStyle: .primary
            ),
            contactSupportAction: {},
            closeAction: {}
        )
    }

    func makeRouteData() -> TransactionDetailsRouteData {
        let record = TransactionRecord(
            hash: "0xsent",
            index: 0,
            source: .single(.init(address: "0xtestaddress", amount: 0.35)),
            destination: .single(.init(address: .user("0x90F79bf6EB2c4f870365E785982E1f101E93b906"), amount: 0.35)),
            fee: Fee(Amount(with: .ethereum(testnet: false), value: 0.0001)),
            status: .confirmed,
            isOutgoing: true,
            type: .transfer,
            date: Date(),
            tokenTransfers: [],
            nonce: nil
        )
        let userWalletInfo = UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01, 0x02, 0x03])),
            config: UserWalletConfigStub(),
            backupState: .valid,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )

        return TransactionDetailsRouteData(
            id: record.id,
            walletModel: CommonWalletModel.previewWalletModel(history: [record]),
            userWalletInfo: userWalletInfo,
            isAccountsMode: false,
            addressBookManager: NoopAddressBookManager()
        )
    }
}
