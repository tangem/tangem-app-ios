//
//  StakingTargetViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemAssets

struct StakingTargetViewData: Hashable, Identifiable {
    var id: Int { hashValue }

    let address: String
    let name: String
    let imageURL: URL?
    let isPartner: Bool
    let subtitleType: SubtitleType?
    let detailsType: DetailsType?

    var subtitle: AttributedString? {
        switch subtitleType {
        case .none:
            return nil
        case .selection(let formatted):
            return string(formatted)
        case .active(let formatted):
            return string(formatted)
        }
    }

    init(
        address: String,
        name: String,
        imageURL: URL?,
        isPartner: Bool = false,
        subtitleType: SubtitleType?,
        detailsType: DetailsType?
    ) {
        self.address = address
        self.name = name
        self.imageURL = imageURL
        self.isPartner = isPartner
        self.subtitleType = subtitleType
        self.detailsType = detailsType
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

extension StakingTargetViewData {
    enum SubtitleType: Hashable {
        /// Short prefix
        case active(formatted: String)
        /// Full prefix
        case selection(formatted: String)
    }

    enum DetailsType: Hashable {
        case checkmark
        case balance(_ balance: BalanceFormatted, action: (() -> Void)? = nil)

        static func == (lhs: StakingTargetViewData.DetailsType, rhs: StakingTargetViewData.DetailsType) -> Bool {
            lhs.hashValue == rhs.hashValue
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .checkmark: hasher.combine("checkmark")
            case .balance(let balance, _): hasher.combine(balance)
            }
        }
    }
}
