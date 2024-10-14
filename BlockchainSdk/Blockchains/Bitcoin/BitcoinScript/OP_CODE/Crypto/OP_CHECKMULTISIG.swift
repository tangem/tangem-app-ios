//
//  OP_CHECKMULTISIG.swift
//
//  Copyright © 2018 BitcoinKit developers
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

// Compares the first signature against each public key until it finds an ECDSA match. Starting
// with the subsequent public key, it compares the second signature against each remaining public key
// until it finds an ECDSA match. The process is repeated until all signatures have been checked or not
// enough public keys remain to produce a successful result. All signatures need to match a public key.
// Because public keys are not checked again if they fail any signature comparison, signatures must be
// placed in the scriptSig using the same order as their corresponding public keys were placed in the
// scriptPubKey or redeemScript. If all signatures are valid, 1 is returned, 0 otherwise. Due to a bug,
// one extra unused value is removed from the stack.
public struct OpCheckMultiSig: OpCodeProtocol {
    public var value: UInt8 { return 0xae }
    public var name: String { return "OP_CHECKMULTISIG" }
}
