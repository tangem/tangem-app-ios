//
//  PhotoSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import UIKit

class PhotoSelectorViewModel: Identifiable {
    let didSelectPhoto: (UIImage?) -> Void

    init(didSelectPhoto: @escaping (UIImage?) -> Void) {
        self.didSelectPhoto = didSelectPhoto
    }
}
