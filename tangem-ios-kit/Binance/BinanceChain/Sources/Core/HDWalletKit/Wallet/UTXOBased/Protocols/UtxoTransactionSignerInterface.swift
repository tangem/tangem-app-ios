//
//  UtxoTransactionSigner.swift
//  HDWalletKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Essentia. All rights reserved.
//

import Foundation

public protocol UtxoTransactionSignerInterface {
    func sign(_ unsignedTransaction: UnsignedTransaction, with key: HDPrivateKey) throws -> HDTransaction
}
