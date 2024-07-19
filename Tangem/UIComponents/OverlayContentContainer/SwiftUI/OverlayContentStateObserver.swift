//
//  OverlayContentStateObserver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

protocol OverlayContentStateObserver {
    @available(*, deprecated, message: "Replace with dedicated type ([REDACTED_INFO])")
    typealias Observer = BottomScrollableSheetStateObserver
    @available(*, deprecated, message: "Replace with dedicated type ([REDACTED_INFO])")
    typealias State = BottomScrollableSheetState

    func addObserver(_ observer: @escaping Observer, forToken token: any Hashable)
    func removeObserver(forToken token: any Hashable)
}
