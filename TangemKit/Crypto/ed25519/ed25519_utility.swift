//
//  ed25519_utility.swift
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
#if NO_USE_CryptoSwift
import CommonCrypto
#else
import CryptoSwift
#endif

extension String {
    func unhexlify() -> [UInt8] {
        var pos = startIndex
        return (0..<count/2).compactMap { _ in
            defer { pos = index(pos, offsetBy: 2) }
            return UInt8(self[pos...index(after: pos)], radix: 16)
        }
    }
}

extension Collection where Iterator.Element == UInt8 {
    func hexDescription() -> String {
        return self.map({ String(format: "%02x", $0) }).joined()
    }
}

func sha512(_ s: [UInt8]) -> [UInt8] {
#if NO_USE_CryptoSwift
    let data = Data(s)
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
	data.withUnsafeBytes { (p: UnsafeRawBufferPointer) -> Void in
		CC_SHA512(p.baseAddress, CC_LONG(data.count), &digest)
    }
    return digest
#else
    return s.sha512()
#endif
}
