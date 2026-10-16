//
//  SwappingSourceAndReceiveTokenHelperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("Swapping the source and the receive token")
struct SwappingSourceAndReceiveTokenHelperTests {
    private let helper = SwappingSourceAndReceiveTokenHelper()

    @Test("A side that is still loading can't be swapped yet")
    func loadingSideIsUnavailable() async {
        let availability = await helper.canBeSwapped(
            source: .success(makeToken()),
            receive: .loading
        )

        #expect(availability.isUnavailable)
    }

    @Test("A receive token that can't be swapped from refuses the swap with its restriction", arguments: SendingRestrictionCase.allCases)
    func restrictedReceiveTokenRefusesTheSwap(restriction: SendingRestrictionCase) async {
        let availability = await helper.canBeSwapped(
            source: .success(makeToken()),
            receive: .success(makeToken(sendingRestriction: restriction.sendingRestriction))
        )

        guard case .restricted(let restrictions) = availability else {
            Issue.record("Expected .restricted, got \(availability)")
            return
        }

        #expect(restrictions == restriction.sendingRestriction)
    }

    @Test("A receive token without restrictions can be swapped")
    func unrestrictedReceiveTokenCanBeSwapped() async {
        let availability = await helper.canBeSwapped(
            source: .success(makeToken()),
            receive: .success(makeToken())
        )

        #expect(availability.isAvailable)
    }

    @Test("A restriction that doesn't stop a swap from the token keeps the swap available")
    func nonBlockingRestrictionKeepsTheSwapAvailable() async {
        let availability = await helper.canBeSwapped(
            source: .success(makeToken()),
            receive: .success(makeToken(sendingRestriction: .zeroWalletBalance))
        )

        #expect(availability.isAvailable)
    }

    @Test("The swap becomes available once the receive token's restriction clears")
    func availabilityFollowsTheReceiveTokenRestrictions() {
        let restrictions = CurrentValueSubject<SendingRestrictions?, Never>(.blockchainLoading)
        let receive = SwapableTokenStub(
            blockchain: .ethereum(testnet: false),
            sendingRestrictionsProvider: SendingRestrictionsSubjectStub(subject: restrictions)
        )
        var availabilities: [Bool] = []

        let subscription = helper.canBeSwappedPublisher(source: .success(makeToken()), receive: .success(receive))
            .sink { availabilities.append($0.isAvailable) }
        restrictions.send(nil)
        subscription.cancel()

        #expect(availabilities == [false, true])
    }

    @Test("A receive-only token can't become the source")
    func receiveOnlyTokenCantBecomeTheSource() async {
        let availability = await helper.canBeSwapped(
            source: .success(makeToken()),
            receive: .success(SendSourceTokenStub(blockchain: .ethereum(testnet: false)))
        )

        #expect(availability.isUnavailable)
    }

    @Test("A receive side waiting for the user's choice keeps the swap available")
    func unselectedReceiveSideKeepsTheSwapAvailable() async {
        let availability = await helper.canBeSwapped(
            source: .success(makeToken()),
            receive: .failure(SwapModel.SwapModelError.tokenSelectionRequired)
        )

        #expect(availability.isAvailable)
    }
}

// MARK: - Helpers

private extension SwappingSourceAndReceiveTokenHelperTests {
    func makeToken(sendingRestriction: SendingRestrictions? = nil) -> SwapableTokenStub {
        SwapableTokenStub(blockchain: .ethereum(testnet: false), sendingRestriction: sendingRestriction)
    }
}

private struct SendingRestrictionsSubjectStub: SendingRestrictionsProvider {
    let subject: CurrentValueSubject<SendingRestrictions?, Never>

    var sendingRestrictionsPublisher: AnyPublisher<SendingRestrictions?, Never> { subject.eraseToAnyPublisher() }
}
