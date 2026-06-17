//
//  SensitiveTextVisibilityState.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A shared state container for sensitive text visibility.
/// This allows the main app target to control visibility while keeping SensitiveText in TangemUI.
public final class SensitiveTextVisibilityState: ObservableObject {
    public static let shared = SensitiveTextVisibilityState()

    @Published public var isHidden: Bool = false
    @Published public var maskedBalanceString: String = MaskedBalance.legacy

    public init() {}
}

public extension SensitiveTextVisibilityState {
    enum MaskedBalance {
        public static let legacy = "\u{2217}\u{2217}\u{2217}"
        public static let redesigned = "\u{2731}\u{2731}\u{2731}"
    }
}
