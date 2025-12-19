//
//  OrganizeTokensListOuterSectionViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAccounts

struct OrganizeTokensListOuterSectionViewModel: Equatable, Identifiable {
    enum SectionStyle: Equatable {
        case invisible
        case `default`(title: String, iconData: AccountIconView.ViewData)
    }

    let id: AnyHashable
    let style: SectionStyle
    let cacheKey: ObjectIdentifier

    init(
        cryptoAccountModel: any CryptoAccountModel,
        style: OrganizeTokensListOuterSectionViewModel.SectionStyle
    ) {
        id = cryptoAccountModel.id
        self.style = style
        cacheKey = ObjectIdentifier(cryptoAccountModel)
    }
}

// MARK: - Convenience extensions

extension OrganizeTokensListOuterSectionViewModel {
    init(
        cryptoAccountModel: any CryptoAccountModel,
        shouldUseInvisibleOuterSection: Bool
    ) {
        let style: OrganizeTokensListOuterSectionViewModel.SectionStyle = shouldUseInvisibleOuterSection
            ? .invisible
            : .default(title: cryptoAccountModel.name, iconData: AccountModelUtils.UI.iconViewData(accountModel: cryptoAccountModel))

        self.init(cryptoAccountModel: cryptoAccountModel, style: style)
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension OrganizeTokensListOuterSectionViewModel.SectionStyle: CustomStringConvertible {
    var description: String {
        switch self {
        case .invisible:
            return "Invisible"
        case .default(let title, _):
            return "Default(\(title))"
        }
    }
}
