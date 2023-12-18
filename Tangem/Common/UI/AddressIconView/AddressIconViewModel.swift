//
//  AddressIconViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockiesSwift

class AddressIconViewModel {
    let image: UIImage
    let size: CGFloat

    init(address: String) {
        let numberOfBlocks = 9
        let scale = 4
        let blockies = Blockies(
            seed: address.lowercased(),
            size: numberOfBlocks,
            scale: scale,
            color: nil,
            bgColor: nil,
            spotColor: nil
        )
        image = blockies.createImage() ?? UIImage()
        size = CGFloat(numberOfBlocks * scale)
    }
}
