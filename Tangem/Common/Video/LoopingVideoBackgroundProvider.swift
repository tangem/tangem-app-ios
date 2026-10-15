//
//  LoopingVideoBackgroundProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol LoopingVideoBackgroundProvider {
    func videoURL() -> URL?
    func handleMissingAsset()
}
