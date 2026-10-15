//
//  TokenActionAvailabilityProviderJointAccountTests.swift
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

@Suite("Tests for the actions a joint account's token holds back as coming soon")
struct TokenActionAvailabilityProviderJointAccountTests {
    private let delegate = JointAccountModelDelegateMock()

    @Test("Sell on a joint account's token is coming soon rather than available")
    func sellOnJointAccountTokenIsComingSoon() {
        let sut = makeSUT(account: makeJointAccount())

        guard case .jointAccountsComingSoon = sut.sellAvailability else {
            Issue.record("Expected .jointAccountsComingSoon, got \(sut.sellAvailability)")
            return
        }

        #expect(!sut.isSellAvailable)
    }

    @Test("Sell on a joint account's token is answered with an alert, like swap")
    func sellOnJointAccountTokenIsAnsweredWithAnAlert() {
        let builder = TokenActionAvailabilityAlertBuilder()
        let status = TokenActionAvailabilityProvider.SellActionAvailabilityStatus.jointAccountsComingSoon

        #expect(builder.alert(for: status) != nil)
    }

    @Test("Sell on a personal account's token is not held back as coming soon")
    func sellOnPersonalAccountTokenIsNotComingSoon() {
        let sut = makeSUT(account: nil)

        if case .jointAccountsComingSoon = sut.sellAvailability {
            Issue.record("A personal account's token must not be held back as coming soon")
        }
    }

    @Test("The sell token selector keeps a joint token tappable to explain itself and the other refusals inert")
    func sellSelectorKeepsJointTokenTappable() {
        let comingSoon = TokenSelectorItem.AvailabilityType.unavailable(reason: .unavailableForSell(.jointAccountsComingSoon))
        let emptyBalance = TokenSelectorItem.AvailabilityType.unavailable(reason: .unavailableForSell(.zeroWalletBalance))

        #expect(!comingSoon.disablesTap)
        #expect(emptyBalance.disablesTap)
    }

    @Test("Swap from a joint account's token is coming soon")
    func swapFromJointAccountTokenIsComingSoon() async {
        await withExpress {
            let sut = makeSUT(account: makeJointAccount())

            guard case .jointAccountsComingSoon = sut.swapSourceAvailability else {
                Issue.record("Expected .jointAccountsComingSoon, got \(sut.swapSourceAvailability)")
                return
            }

            #expect(!sut.isSwapAsSourceAvailable)
        }
    }

    @Test("The swap direction picks the side whose availability is checked")
    func swapDirectionPicksTheCheckedSide() async {
        await withExpress {
            let sut = makeSUT(account: makeJointAccount())

            #expect(!sut.isSwapAvailable(direction: .from))
            #expect(sut.isSwapAvailable(direction: .to))
        }
    }

    @Test("Swap into a joint account's token is available")
    func swapIntoJointAccountTokenIsAvailable() async {
        await withExpress {
            let sut = makeSUT(account: makeJointAccount())

            guard case .available = sut.swapReceiveAvailability else {
                Issue.record("Expected .available, got \(sut.swapReceiveAvailability)")
                return
            }
        }
    }

    @Test("Swap on a personal account's token is available on both sides")
    func swapOnPersonalAccountTokenIsAvailableOnBothSides() async {
        await withExpress {
            let sut = makeSUT(account: nil)

            guard case .available = sut.swapSourceAvailability, case .available = sut.swapReceiveAvailability else {
                Issue.record("Expected .available on both sides, got \(sut.swapSourceAvailability) and \(sut.swapReceiveAvailability)")
                return
            }
        }
    }

    @Test("Swap into a custom token is refused")
    func swapIntoCustomTokenIsRefused() async {
        await withExpress {
            let walletModel = makeWalletModel(account: nil)
            walletModel.isCustomMock = true

            let sut = makeSUT(walletModel: walletModel)

            guard case .customToken = sut.swapReceiveAvailability else {
                Issue.record("Expected .customToken, got \(sut.swapReceiveAvailability)")
                return
            }
        }
    }

    @Test("Swap into a token with an unmet asset requirement is refused")
    func swapIntoTokenWithMissingAssetRequirementIsRefused() async {
        await withExpress {
            let walletModel = makeWalletModel(account: nil)
            walletModel.assetRequirementsManagerMock = AssetRequirementsManagerStub(
                condition: .paidTransactionWithFee(blockchain: .polygon(testnet: false), transactionAmount: nil, feeAmount: nil)
            )

            let sut = makeSUT(walletModel: walletModel)

            guard case .missingAssetRequirement = sut.swapReceiveAvailability else {
                Issue.record("Expected .missingAssetRequirement, got \(sut.swapReceiveAvailability)")
                return
            }
        }
    }

    @Test("Swap into a token waits while Express availability is loading")
    func swapIntoTokenWaitsForExpress() async {
        await withExpress(swapState: .notLoaded, updateState: .updating) {
            let sut = makeSUT(account: nil)

            guard case .expressLoading = sut.swapReceiveAvailability else {
                Issue.record("Expected .expressLoading, got \(sut.swapReceiveAvailability)")
                return
            }
        }
    }

    @Test("Swap into a token is refused when Express availability failed to load")
    func swapIntoTokenIsRefusedWhenExpressFailed() async {
        await withExpress(swapState: .notLoaded, updateState: .failed(error: URLError(.notConnectedToInternet))) {
            let sut = makeSUT(account: nil)

            guard case .expressUnreachable = sut.swapReceiveAvailability else {
                Issue.record("Expected .expressUnreachable, got \(sut.swapReceiveAvailability)")
                return
            }
        }
    }

    @Test("Swap into a token ignores what keeps it from being sent", arguments: SendingRestrictionCase.allCases)
    func swapIntoTokenIgnoresSendingRestrictions(restriction: SendingRestrictionCase) async {
        await withExpress {
            let walletModel = makeWalletModel(account: nil)
            walletModel.sendingRestrictionsMock = restriction.sendingRestriction

            let sut = makeSUT(walletModel: walletModel)

            #expect(!sut.isSwapAsSourceAvailable)
            #expect(sut.isSwapAsReceiveAvailable)
        }
    }

    @Test("The swap token selector keeps a joint source tappable to explain itself")
    func swapSelectorKeepsJointSourceTappable() {
        let comingSoon = TokenSelectorItem.AvailabilityType.unavailable(reason: .unavailableForSwap(.sourceState(.jointAccountsComingSoon)))
        let customSource = TokenSelectorItem.AvailabilityType.unavailable(reason: .unavailableForSwap(.sourceState(.customToken)))

        #expect(!comingSoon.disablesTap)
        #expect(customSource.disablesTap)
    }
}

// MARK: - Helpers

private extension TokenActionAvailabilityProviderJointAccountTests {
    func withExpress(
        swapState: TokenItemExpressState = .available,
        updateState: ExpressAvailabilityUpdateState = .updated,
        _ body: () -> Void
    ) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousProvider = InjectedValues[\.expressAvailabilityProvider]
            InjectedValues[\.expressAvailabilityProvider] = SwapExpressAvailabilityProviderStub(swapState: swapState, updateState: updateState)
            defer { InjectedValues[\.expressAvailabilityProvider] = previousProvider }

            body()
        }
    }

    func makeSUT(account: (any CryptoAccountModel)?) -> TokenActionAvailabilityProvider {
        makeSUT(walletModel: makeWalletModel(account: account))
    }

    func makeSUT(walletModel: WalletModelTestsMock) -> TokenActionAvailabilityProvider {
        TokenActionAvailabilityProvider(userWalletInfo: makeUserWalletInfo(), walletModel: walletModel)
    }

    func makeWalletModel(account: (any CryptoAccountModel)?) -> WalletModelTestsMock {
        WalletModelTestsMock(
            tokenItem: .blockchain(.init(.polygon(testnet: false), derivationPath: nil)),
            isEmpty: false,
            account: account
        )
    }

    func makeUserWalletInfo() -> UserWalletInfo {
        UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01])),
            config: UserWalletConfigStub(supportedBlockchains: [.polygon(testnet: false)]),
            backupState: .valid,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )
    }

    func makeJointAccount() -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, accountType: .joint, onArchive: { _ in }),
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint),
            accountPolicy: JointAccountPolicy(membersCount: 2, signersCount: 2),
            accountStatus: .pending,
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: JointAccountMembersServiceMock(),
            delegate: delegate
        )
    }
}

// MARK: - Test cases

enum SendingRestrictionCase: CaseIterable {
    case hasOnlyCachedBalance
    case blockchainLoading
    case cantSignLongTransactions

    var sendingRestriction: SendingRestrictions {
        switch self {
        case .hasOnlyCachedBalance: .hasOnlyCachedBalance
        case .blockchainLoading: .blockchainLoading
        case .cantSignLongTransactions: .cantSignLongTransactions
        }
    }
}
