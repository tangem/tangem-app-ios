//
//  ed25519_verify.swift
//
//  Copyright 2017 pebble8888. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//	arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//	including commercial applications, and to alter it and redistribute it
//	freely, subject to the following restrictions:
//
//	1. The origin of this software must not be misrepresented; you must not
//	claim that you wrote the original software. If you use this software
//	in a product, an acknowledgment in the product documentation would be
//	appreciated but is not required.
//
//	2. Altered source versions must be plainly marked as such, and must not be
//	misrepresented as being the original software.
//
//	3. This notice may not be removed or altered from any source distribution.
//

import Foundation

public extension Ed25519 {
    /// verify
	/// - Parameters:
	///   - sig: signature 64bytes (R 32byte + S 32byte)
	///   - m: message
	///   - pk: public key 32bytes
	static func verify(_ sig: [UInt8], _ m: [UInt8], _ pk: [UInt8]) -> Bool {
		if pk.count != 32 {
			return false
		}
		if sig.count != 64 {
			return false
		}
		let smlen = 64 + m.count
        var sm = [UInt8](repeating: 0, count: smlen)
		var rcopy = [UInt8](repeating: 0, count: 32) // point R
		var k = [UInt8](repeating: 0, count: 64)
		var rcheck = [UInt8](repeating: 0, count: 32)
		var ge_a = ge() // unpacked public info from pk argument
		var ge_b = ge()
		var sc_k = sc() // integer k
		var sc_s = sc()

		// rapid check if S is smaller than group order
        if sig[63] & UInt8(224) != 0 {
			return false
		}
		// exact check if S is smaller than group order
		if !sc.sc25519_less_order(Array(sig[32..<64])) {
			return false
		}
        if !ge.ge25519_unpackneg_vartime(&ge_a, pk) {
			return false
		}

        for i in 0..<32 {
            rcopy[i] = sig[i] // point R
        }

        sc.sc25519_from32bytes(&sc_s, Array(sig[32..<64])) // integer S

		// signature 64 bytes(R 32byte + S 32byte)
		for i in 0..<32 {
			sm[i] = sig[i]
		}
		// R 32byte + A 32byte
		for i in 0..<32 {
			sm[32+i] = pk[i]
		}
		// R 32byte + A 32byte + message
		for i in 0..<m.count {
			sm[64+i] = m[i]
		}
        crypto_hash_sha512(&k, sm, len: smlen)
        sc.sc25519_from64bytes(&sc_k, k) // integer k

        // - A k + G s
        ge.ge25519_double_scalarmult_vartime(&ge_b, ge_a, sc_k, ge.ge25519_base, sc_s)
        ge.ge25519_pack(&rcheck, ge_b)

		// check R == - A k + G s
        return rcopy == rcheck
    }
}
