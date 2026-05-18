//
//  TransferWithSwapModelInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

/// Exposes the `TransferWithSwapModel` mode flag to consumers (notification managers,
/// view-models) that need to react to swap ↔ transfer transitions.
protocol TransferWithSwapModelInput: AnyObject {
    var isTransferMode: Bool { get }
    var isTransferModePublisher: AnyPublisher<Bool, Never> { get }
}
