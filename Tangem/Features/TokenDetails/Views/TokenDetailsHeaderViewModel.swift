//
//  TokenDetailsHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

class TokenDetailsHeaderViewModel {
    let tokenName: String
    let imageURL: URL?
    let customTokenColor: Color?
    var networkPrefix: String = ""
    var networkIconAsset: ImageType?
    var networkSuffix: String?

    private let tokenItem: TokenItem

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem

        if let id = tokenItem.id {
            imageURL = IconURLBuilder().tokenIconURL(id: id)
        } else {
            imageURL = nil
        }
        customTokenColor = tokenItem.token?.customTokenColor
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
        networkIconAsset = nil
        networkSuffix = nil
    }

    private func prepareTokenComponents() {
        let tokenTypePrefix = tokenItem.blockchain.tokenTypeName ?? ""
        let networkNameSuffix = tokenItem.blockchain.displayName
        let blockchainIconProvider = NetworkImageProvider()

        let localizedString = Localization.tokenDetailsTokenTypeSubtitle(tokenTypePrefix, networkNameSuffix)
        do {
            let parser = LocalizationIconParser()
            let components = try parser.parse(localizedString)

            if tokenTypePrefix.isEmpty {
                networkPrefix = components.prefix.capitalizingFirstLetter()
            } else {
                networkPrefix = components.prefix
            }
            networkSuffix = components.suffix
        } catch {
            networkPrefix = localizedString
            networkSuffix = nil
        }

        networkIconAsset = blockchainIconProvider.provide(by: tokenItem.blockchain, filled: true)
    }
}
