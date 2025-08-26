//
//  WalletSelectorInfoProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Combine

protocol WalletSelectorInfoProvider: AnyObject {
    var name: String { get }
    var updatePublisher: AnyPublisher<UpdateResult, Never> { get }
    var walletImageProvider: WalletImageProviding { get }
}
