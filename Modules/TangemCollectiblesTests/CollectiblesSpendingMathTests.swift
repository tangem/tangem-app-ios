//
//  CollectiblesSpendingMathTests.swift
//  TangemCollectiblesTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
@testable import TangemCollectibles

@Suite("CollectiblesVaultProgram.SpendingMath")
struct CollectiblesSpendingMathTests {
    // MARK: - Daily budget

    @Test("The remaining budget subtracts what was spent within the same day bucket")
    func remainingTodaySubtractsSpentWithinTheSameDayBucket() {
        let now = Date(timeIntervalSince1970: 20_690 * 86_400 + 12 * 3_600)

        let remaining = CollectiblesVaultProgram.SpendingMath.remainingToday(
            dailyCap: 900,
            spentToday: 250,
            dayIndex: 20_690,
            now: now
        )

        #expect(remaining == 650)
    }

    @Test("A stale day bucket grants the full budget")
    func remainingTodayGrantsFullBudgetForAStaleDayBucket() {
        // spent_today rolls over lazily (only inside purchase_pack), so a stale bucket means full budget
        let now = Date(timeIntervalSince1970: 20_691 * 86_400 + 1)

        let remaining = CollectiblesVaultProgram.SpendingMath.remainingToday(
            dailyCap: 900,
            spentToday: 900,
            dayIndex: 20_690,
            now: now
        )

        #expect(remaining == 900)
    }

    @Test("Spending still counts when the device clock lags the chain")
    func remainingTodayStillCountsSpentWhenDeviceClockLagsTheChain() {
        // On chain day_index can never exceed the cluster's own day, so a future bucket
        // means the DEVICE clock is behind — the program will not roll spent_today over,
        // and granting the full budget here over-reports what a spin can actually pass
        let now = Date(timeIntervalSince1970: 20_690 * 86_400 + 86_399)

        let remaining = CollectiblesVaultProgram.SpendingMath.remainingToday(
            dailyCap: 900,
            spentToday: 250,
            dayIndex: 20_691,
            now: now
        )

        #expect(remaining == 650)
    }

    @Test("The remaining budget clamps to zero when spending exceeds a lowered cap")
    func remainingTodayClampsToZeroWhenSpentExceedsALoweredCap() {
        // daily_cap can be lowered mid-day, legally leaving spent_today above it —
        // unsigned subtraction here is the classic wrong-UI / rejected-tx (6006) source
        let now = Date(timeIntervalSince1970: 20_690 * 86_400 + 1)

        let remaining = CollectiblesVaultProgram.SpendingMath.remainingToday(
            dailyCap: 100,
            spentToday: 250,
            dayIndex: 20_690,
            now: now
        )

        #expect(remaining == 0)
    }

    // MARK: - Spin permission

    @Test("Amount plus fee is checked against both caps")
    func fitsCapsChecksAmountPlusFeeAgainstBothCaps() {
        let now = Date(timeIntervalSince1970: 20_690 * 86_400 + 1)
        let vault = makeVault(perSpinCap: 101, dailyCap: 300, spentToday: 199, dayIndex: 20_690)

        // total == perSpinCap == remaining(101) — boundary passes
        #expect(CollectiblesVaultProgram.SpendingMath.fitsCaps(amount: 100, feeAmount: 1, vault: vault, now: now))
        // remaining is 101, total 102 > per-spin cap
        #expect(!CollectiblesVaultProgram.SpendingMath.fitsCaps(amount: 101, feeAmount: 1, vault: vault, now: now))
    }

    @Test("A total above the per-spin cap does not fit even when the daily remainder allows it")
    func fitsCapsRejectsWhenTotalExceedsThePerSpinCap() {
        let now = Date(timeIntervalSince1970: 20_690 * 86_400 + 1)
        let vault = makeVault(perSpinCap: 101, dailyCap: 300, spentToday: 0, dayIndex: 20_690)

        #expect(!CollectiblesVaultProgram.SpendingMath.fitsCaps(amount: 101, feeAmount: 1, vault: vault, now: now))
    }

    @Test("A spin larger than the daily remainder does not fit")
    func fitsCapsRejectsWhenDailyRemainderIsTooSmall() {
        let now = Date(timeIntervalSince1970: 20_690 * 86_400 + 1)
        let vault = makeVault(perSpinCap: 500, dailyCap: 300, spentToday: 250, dayIndex: 20_690)

        // total = 101 > remaining 50
        #expect(!CollectiblesVaultProgram.SpendingMath.fitsCaps(amount: 100, feeAmount: 1, vault: vault, now: now))
    }

    @Test("A total that overflows does not fit")
    func fitsCapsRejectsOnTotalOverflow() {
        let now = Date(timeIntervalSince1970: 20_690 * 86_400 + 1)
        let vault = makeVault(perSpinCap: .max, dailyCap: .max, spentToday: 0, dayIndex: 20_690)

        #expect(!CollectiblesVaultProgram.SpendingMath.fitsCaps(amount: .max, feeAmount: 1, vault: vault, now: now))
    }

    // MARK: - Fee corridor

    @Test("The fee corridor spans from the minimum to the maximum bps")
    func feeCorridorSpansFromMinToMaxFeeBps() {
        let config = makeConfig(minFeeBps: 100, maxFeeBps: 300)

        let corridor = CollectiblesVaultProgram.SpendingMath.feeCorridor(amount: 1_000_000, config: config)

        #expect(corridor == 10_000 ... 30_000)
    }

    /// `minFeeBps`/`maxFeeBps` name the program config's stored order, not which is numerically smaller —
    /// the corridor still has to come out the right way round if the admin ever stores them inverted.
    @Test("The fee corridor orders its bounds regardless of the field order")
    func feeCorridorOrdersItsBoundsRegardlessOfFieldOrder() {
        let config = makeConfig(minFeeBps: 300, maxFeeBps: 100)

        let corridor = CollectiblesVaultProgram.SpendingMath.feeCorridor(amount: 1_000_000, config: config)

        #expect(corridor == 10_000 ... 30_000)
    }

    @Test("Fees inside the corridor fit", arguments: [10_000, 20_000, 30_000] as [UInt64])
    func fitsFeeCorridorAcceptsFeesInsideItsBounds(feeAmount: UInt64) {
        let config = makeConfig(minFeeBps: 100, maxFeeBps: 300)

        #expect(CollectiblesVaultProgram.SpendingMath.fitsFeeCorridor(amount: 1_000_000, feeAmount: feeAmount, config: config))
    }

    @Test("Fees outside the corridor do not fit", arguments: [9_999, 30_001] as [UInt64])
    func fitsFeeCorridorRejectsFeesOutsideItsBounds(feeAmount: UInt64) {
        let config = makeConfig(minFeeBps: 100, maxFeeBps: 300)

        #expect(!CollectiblesVaultProgram.SpendingMath.fitsFeeCorridor(amount: 1_000_000, feeAmount: feeAmount, config: config))
    }

    /// `bps * amount` alone would overflow `UInt64` for a large enough amount; the full-width multiply and
    /// divide must not trap where a naive `amount * bps / 10_000` would. `bps == 10_000` keeps
    /// `product.high` just under the denominator, so this alone never reaches the saturating fallback below.
    @Test("The corridor does not overflow for a large amount")
    func fitsFeeCorridorDoesNotOverflowForALargeAmount() {
        let config = makeConfig(minFeeBps: 0, maxFeeBps: 10_000)

        #expect(CollectiblesVaultProgram.SpendingMath.fitsFeeCorridor(amount: .max, feeAmount: .max, config: config))
    }

    /// A `bps` above 10_000 (a misconfigured on-chain config — fees were never meant to exceed the amount)
    /// pushes `product.high` past the denominator, so the bound must saturate to `.max` instead of the
    /// division trapping or wrapping.
    @Test("The corridor saturates when bps exceed the denominator")
    func feeCorridorSaturatesToMaxWhenBpsExceedsTheDenominator() {
        let config = makeConfig(minFeeBps: 0, maxFeeBps: 10_001)

        let corridor = CollectiblesVaultProgram.SpendingMath.feeCorridor(amount: .max, config: config)

        #expect(corridor.upperBound == .max)
    }
}

// MARK: - Private implementation

private extension CollectiblesSpendingMathTests {
    func makeVault(
        perSpinCap: UInt64 = 1_000,
        dailyCap: UInt64,
        spentToday: UInt64,
        dayIndex: Int64
    ) -> CollectiblesVaultInfo {
        CollectiblesVaultInfo(
            vaultAddress: "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA",
            sessionKey: Data(repeating: 0xBB, count: 32),
            perSpinCap: perSpinCap,
            dailyCap: dailyCap,
            spentToday: spentToday,
            dayIndex: dayIndex
        )
    }

    func makeConfig(minFeeBps: UInt16, maxFeeBps: UInt16) -> CollectiblesConfigInfo {
        CollectiblesConfigInfo(
            usdcMint: Data(repeating: 0, count: 32),
            collectiblesUsdcAccount: Data(repeating: 0, count: 32),
            feeUsdcAccount: Data(repeating: 0, count: 32),
            minFeeBps: minFeeBps,
            maxFeeBps: maxFeeBps
        )
    }
}
