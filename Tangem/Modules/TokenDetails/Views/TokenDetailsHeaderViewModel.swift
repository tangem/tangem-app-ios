//
//  TokenDetailsHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class TokenDetailsHeaderViewModel {
    let tokenName: String
    let tokenIconModel: TokenIconViewModel
    var networkPrefix: String = ""
    var networkIconName: String?
    var networkSuffix: String?

    private let tokenItem: TokenItem

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
        tokenIconModel = .init(tokenItem: tokenItem)
        tokenName = tokenItem.name

        prepare()
    }

    private func prepare() {
        if tokenItem.isToken {
            prepareTokenComponents()
        } else {
            prepareCoinComponents()
        }
    }

    private func prepareCoinComponents() {
        networkPrefix = Localization.commonMainNetwork
        networkIconName = nil
        networkSuffix = nil
    }

    private func prepareTokenComponents() {
        let tokenTypePrefix = tokenItem.blockchain.tokenTypeName ?? ""
        let networkNameSuffix = tokenItem.blockchain.displayName

        let localizedString = Localization.tokenDetailsTokenTypeSubtitle(tokenTypePrefix, networkNameSuffix)
        do {
            let parser = LocalizationIconParser()
            let components = try parser.parse(localizedString)

            if tokenTypePrefix.isEmpty {
                networkPrefix = components.prefix.trimmingCharacters(in: .whitespaces).capitalizingFirstLetter()
            } else {
                networkPrefix = components.prefix
            }
            networkSuffix = components.suffix.trimmingCharacters(in: .whitespaces)
        } catch {
            networkPrefix = localizedString
            networkSuffix = nil
        }

        networkIconName = tokenItem.blockchain.iconNameFilled
    }
}
