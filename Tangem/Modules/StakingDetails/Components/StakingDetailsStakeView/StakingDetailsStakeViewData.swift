//
//  StakingDetailsStakeViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import SwiftUI

struct StakingDetailsStakeViewData: Identifiable {
    var id: Int { hashValue }

    let title: String
    let icon: IconType
    let inProgress: Bool
    let subtitleType: SubtitleType?
    let balance: WalletModel.BalanceFormatted
    let action: (() -> Void)?

    var subtitle: AttributedString? {
        switch subtitleType {
        case .none:
            return nil
        case .locked:
            return string(Localization.stakingTapToUnlock)
        case .warmup(let period):
            return string(Localization.stakingDetailsWarmupPeriod, accent: period)
        case .active(let apr):
            return string(Localization.stakingDetailsApr, accent: apr)
        case .unbondingPeriod(let period):
            return string(Localization.stakingDetailsUnbondingPeriod, accent: period)
        case .unbonding(let unlitDate):
            let (text, accent) = preparedUntil(unlitDate)
            return string(text, accent: accent)
        case .withdraw:
            return string(Localization.stakingReadyToWithdraw)
        }
    }

    private func preparedUntil(_ date: Date) -> (full: String, accent: String) {
        if Calendar.current.isDateInToday(date) {
            return (Localization.stakingUnbonding, Localization.commonToday)
        }

        guard let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day else {
            let formatted = date.formatted(.dateTime)
            return (Localization.stakingUnbondingIn, formatted)
        }

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.day]
        let formatted = formatter.string(from: DateComponents(day: days)) ?? days.formatted()

        return (Localization.stakingUnbondingIn, formatted)
    }

    private func string(_ text: String, accent: String? = nil) -> AttributedString {
        var string = AttributedString(text)
        string.foregroundColor = Colors.Text.tertiary
        string.font = Fonts.Regular.caption1

        if let accent {
            var accent = AttributedString(accent)
            accent.foregroundColor = Colors.Text.accent
            accent.font = Fonts.Regular.caption1
            return string + " " + accent
        }

        return string
    }
}

extension StakingDetailsStakeViewData: Hashable {
    static func == (lhs: StakingDetailsStakeViewData, rhs: StakingDetailsStakeViewData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(subtitleType)
        hasher.combine(icon)
        hasher.combine(balance)
        hasher.combine(inProgress)
    }
}

extension StakingDetailsStakeViewData {
    enum SubtitleType: Hashable {
        case warmup(period: String)
        case active(apr: String)
        case unbonding(until: Date)
        case unbondingPeriod(period: String)
        case withdraw
        case locked
    }

    enum IconType: Hashable {
        case icon(ImageType, color: Color)
        case image(url: URL?)

        func hash(into hasher: inout Hasher) {
            switch self {
            case .icon(let imageType, _):
                hasher.combine(imageType)
            case .image(let url):
                hasher.combine(url)
            }
        }
    }
}
