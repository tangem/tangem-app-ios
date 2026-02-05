//
//  NFTAssetDetailsRoutable.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

public protocol NFTAssetDetailsRoutable: AnyObject {
    func openSend(for asset: NFTAsset, in collection: NFTCollection)
    func openInfo(with viewData: NFTAssetExtendedInfoViewData)
    func openTraits(with data: KeyValuePanelViewData)
    func openExplorer(for asset: NFTAsset)
}
