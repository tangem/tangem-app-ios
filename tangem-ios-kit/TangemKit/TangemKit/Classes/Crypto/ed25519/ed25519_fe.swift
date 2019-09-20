//
//  ed25519_fe.swift
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

// field element
struct fe: CustomDebugStringConvertible {
    // WINDOWSIZE = 1, 8bit * 32 = 256bit
	// val = 2^(31*8) * v[31]
	//     + 2^(30*8) * v[30]
	//     + ..
	//     + 2^(2*8) * v[2]
	//     + 2^(1*8) * v[1]
	//     + 2^(0*8) * v[0]
    public var v: [UInt32] // size:32

    public var debugDescription: String {
        return v.map({ String(format: "%d ", $0)}).joined()
    }

    public init() {
        v = [UInt32](repeating: 0, count: 32)
    }

    public init(_ v: [UInt32]) {
		assert(v.count == 32)
        self.v = v
    }

	/* 16-bit inputs */	
    static func equal(_ a: UInt32, _ b: UInt32) -> UInt32 {
        return a == b ? 1 : 0
    }

    // greater equal
	/* 16-bit inputs */
    static func ge(_ a: UInt32 , _ b: UInt32) -> UInt32 {
        return a >= b ? 1 : 0
    }

    // 19 * a = (2^4 + 2^1 + 2^0) * a
    static func times19(_ a: UInt32) -> UInt32 {
        return (a << 4) + (a << 1) + a
    }

    // 38 * a = (2^5 + 2^2 + 2^1) * a
    static func times38(_ a: UInt32) -> UInt32 {
        return (a << 5) + (a << 2) + (a << 1)
    }

	// q = 2^255 - 19 = 2^(31*8)*(2^7) - 19
	// 7fff ffff ffff ffff ffff ffff ffff ffff
	// ffff ffff ffff ffff ffff ffff ffff ffed
	// 0x7f = 0111 1111 = 2^7-1
	// 0xff = 1111 1111 = 2^8-1
    static func reduce_add_sub(_ r: inout fe) {
        var t: UInt32
		var s: UInt32
        // 32bit / 8bit = 4
        for _ in 0..<4 {
			// use q = 2^(31*8)*(2^7) - 19
            t = r.v[31] >> 7
            r.v[31] &= 0x7f
            t = times19(t)
            r.v[0] += t
			// move up
            for i in 0..<31 {
                s = r.v[i] >> 8
                r.v[i+1] += s
                r.v[i] &= 0xff
            }
        }
    }

    static func reduce_mul(_ r: inout fe) {
        var t: UInt32
		var s: UInt32
        for _ in 0..<2 {
			// use q = 2^(31*8)*(2^7) - 19
            t = r.v[31] >> 7
            r.v[31] &= 0x7f
            t = times19(t)
            r.v[0] += t
			// move up
            for i in 0..<31 {
                s = r.v[i] >> 8
                r.v[i+1] += s
                r.v[i] &= 0xff
            }
        }
    }

    /* reduction modulo 2^255-19 */
	// 0x7f = 127
	// 0xff = 255
	// 0xed = 237
    static func fe25519_freeze(_ r: inout fe) {
		assert(r.v[31] <= 0xff)
        var m: UInt32 = equal(r.v[31], 127)
        for i in stride(from: 30, to: 0, by: -1) {
            m &= equal(r.v[i], 255)
        }
        m &= ge(r.v[0], 237)
		// Here if value is greater than q,  m is 1 or 0.
        m = UInt32(bitPattern: Int32(m) * -1)
		// m is 0xffffffff or 0x0

        r.v[31] -= (m&127)
        for i in stride(from: 30, to: 0, by: -1) {
            r.v[i] -= m&255
        }
        r.v[0] -= m&237
    }

    static func fe25519_unpack(_ r: inout fe, _ x: [UInt8]/* 32 */) {
		assert(x.count == 32)
        for i in 0..<32 {
            r.v[i] = UInt32(x[i])
        }
        r.v[31] &= 127 // remove parity
    }

    /* Assumes input x being reduced mod 2^255 */
    static func fe25519_pack(_ r: inout [UInt8] /* 32 or more */, _ x: fe) {
		assert(r.count >= 32)
        var y: fe = x
        fe.fe25519_freeze(&y)
        for i in 0..<32 {
            r[i] = UInt8(y.v[i])
        }
    }

    // freeze input before calling iszero
    static func fe25519_iszero(_ x: fe) -> Bool {
        var t: fe = x
        fe.fe25519_freeze(&t)
        var r = fe.equal(t.v[0], 0)
        for i in 1..<32 {
            r &= fe.equal(t.v[i], 0)
        }
        return r != 0
    }

    // is equal after freeze
    static func fe25519_iseq_vartime(_ x: fe, _ y: fe) -> Bool {
        var t1 = x
        var t2 = y
        fe.fe25519_freeze(&t1)
        fe.fe25519_freeze(&t2)
        for i in 0..<32 {
            if t1.v[i] != t2.v[i] {
                return false
            }
        }
        return true
    }

	// conditional move
    static func fe25519_cmov(_ r: inout fe, _ x: fe, _ b: UInt8) {
        let mask: UInt32 = UInt32(bitPattern: Int32(b) * -1)
        for i in 0..<32 {
			// ^ means xor
            r.v[i] ^= mask & (x.v[i] ^ r.v[i])
        }
    }

    // odd:1 even:0
    static func fe25519_getparity(_ x: fe) -> UInt8 {
        var t = x
        fe.fe25519_freeze(&t)
        return UInt8(t.v[0] & 1)
    }

    // [REDACTED_USERNAME]  r = 1
    static func fe25519_setone(_ r: inout fe) {
        r.v[0] = 1
        for i in 1..<32 {
            r.v[i] = 0
        }
    }

    // [REDACTED_USERNAME]  r = 0
    static func fe25519_setzero(_ r: inout fe) {
        for i in 0..<32 {
            r.v[i] = 0
        }
    }

	/// r = -x
    static func fe25519_neg(_ r: inout fe, _ x: fe) {
        var t = fe()
        for i in 0..<32 {
            t.v[i] = x.v[i]
        }
        fe25519_setzero(&r)
        fe25519_sub(&r, r, t)
    }

	/// r = x + y
    static func fe25519_add(_ r: inout fe, _ x: fe, _ y: fe) {
        for i in 0..<32 {
            r.v[i] = x.v[i] + y.v[i]
        }
        fe.reduce_add_sub(&r)
    }

	///  r = x - y
	///  q = 2 ** 255 - 19
	///  7fff ffff ffff ffff ffff ffff ffff ffff
	///  ffff ffff ffff ffff ffff ffff ffff ffed
	///  2 * 7f = fe
    ///  2 * ff = 1fe
    ///  2 * ed = 1da
	/// [REDACTED_USERNAME] result is reduced
    static func fe25519_sub(_ r: inout fe, _ x: fe, _ y: fe) {
		// t = 2 * q + x
        var t = [UInt32](repeating: 0, count: 32)
        t[0] = x.v[0] + 0x1da	// LSB
        for i in 1..<31 { t[i] = x.v[i] + 0x1fe }
        t[31] = x.v[31] + 0xfe	// MSB
		// r = t - y
        for i in 0..<32 { r.v[i] = t[i] - y.v[i] }
        fe.reduce_add_sub(&r)
    }

    /// r = x * y
    static func fe25519_mul(_ r: inout fe, _ x: fe, _ y: fe) {
        var t = [UInt32](repeating: 0, count: 63)

        for i in 0..<32 {
            for j in 0..<32 {
                t[i+j] += x.v[i] * y.v[j]
            }
        }

		// 2q = 2^256 - 2*19
		// so 2^256 = 2*19
        for i in 32..<63 {
            r.v[i-32] = t[i-32] + fe.times38(t[i])
        }
        r.v[31] = t[31] /* result now in r[0]...r[31] */

        fe.reduce_mul(&r)
    }

    /// r = x^2
    static func fe25519_square(_ r: inout fe, _ x: fe) {
        fe25519_mul(&r, x, x)
    }

	/// r = 1/x
    /// q = 2^255-19
    /// 1/a = a^(q-2)
    /// q-2 = 2^255-21
    static func fe25519_invert(_ r: inout fe, _ x: fe) {
        var z2 = fe()
        var z9 = fe()
        var z11 = fe()
        var z2_5_0 = fe()
        var z2_10_0 = fe()
        var z2_20_0 = fe()
        var z2_50_0 = fe()
        var z2_100_0 = fe()
        var t0 = fe()
        var t1 = fe()

        /* 2 */ fe25519_square(&z2, x)
        /* 4 */ fe25519_square(&t1, z2)
        /* 8 */ fe25519_square(&t0, t1)
        /* 9 */ fe25519_mul(&z9, t0, x)
        /* 11 */ fe25519_mul(&z11, z9, z2)
        /* 22 */ fe25519_square(&t0, z11)
        /* 2^5 - 2^0 = 31 */ fe25519_mul(&z2_5_0, t0, z9)

        /* 2^6 - 2^1 */ fe25519_square(&t0, z2_5_0)
        /* 2^7 - 2^2 */ fe25519_square(&t1, t0)
        /* 2^8 - 2^3 */ fe25519_square(&t0, t1)
        /* 2^9 - 2^4 */ fe25519_square(&t1, t0)
        /* 2^10 - 2^5 */ fe25519_square(&t0, t1)
        /* 2^10 - 2^0 */ fe25519_mul(&z2_10_0, t0, z2_5_0)

        /* 2^11 - 2^1 */ fe25519_square(&t0, z2_10_0)
        /* 2^12 - 2^2 */ fe25519_square(&t1, t0)
        /* 2^20 - 2^10 */ for _ in stride(from: 2, to: 10, by: 2) { fe25519_square(&t0, t1); fe25519_square(&t1, t0) }
        /* 2^20 - 2^0 */ fe25519_mul(&z2_20_0, t1, z2_10_0)

        /* 2^21 - 2^1 */ fe25519_square(&t0, z2_20_0)
        /* 2^22 - 2^2 */ fe25519_square(&t1, t0)
        /* 2^40 - 2^20 */ for _ in stride(from: 2, to: 20, by: 2) { fe25519_square(&t0, t1); fe25519_square(&t1, t0) }
        /* 2^40 - 2^0 */ fe25519_mul(&t0, t1, z2_20_0)

        /* 2^41 - 2^1 */ fe25519_square(&t1, t0)
        /* 2^42 - 2^2 */ fe25519_square(&t0, t1)
        /* 2^50 - 2^10 */ for _ in stride(from: 2, to: 10, by: 2) { fe25519_square(&t1, t0); fe25519_square(&t0, t1) }
        /* 2^50 - 2^0 */ fe25519_mul(&z2_50_0, t0, z2_10_0)

        /* 2^51 - 2^1 */ fe25519_square(&t0, z2_50_0)
        /* 2^52 - 2^2 */ fe25519_square(&t1, t0)
        /* 2^100 - 2^50 */ for _ in stride(from: 2, to: 50, by: 2) { fe25519_square(&t0, t1); fe25519_square(&t1, t0) }
        /* 2^100 - 2^0 */ fe25519_mul(&z2_100_0, t1, z2_50_0)

        /* 2^101 - 2^1 */ fe25519_square(&t1, z2_100_0)
        /* 2^102 - 2^2 */ fe25519_square(&t0, t1)
        /* 2^200 - 2^100 */ for _ in stride(from: 2, to: 100, by: 2) { fe25519_square(&t1, t0); fe25519_square(&t0, t1) }
        /* 2^200 - 2^0 */ fe25519_mul(&t1, t0, z2_100_0)

        /* 2^201 - 2^1 */ fe25519_square(&t0, t1)
        /* 2^202 - 2^2 */ fe25519_square(&t1, t0)
        /* 2^250 - 2^50 */ for _ in stride(from: 2, to: 50, by: 2) { fe25519_square(&t0, t1); fe25519_square(&t1, t0) }
        /* 2^250 - 2^0 */ fe25519_mul(&t0, t1, z2_50_0)

        /* 2^251 - 2^1 */ fe25519_square(&t1, t0)
        /* 2^252 - 2^2 */ fe25519_square(&t0, t1)
        /* 2^253 - 2^3 */ fe25519_square(&t1, t0)
        /* 2^254 - 2^4 */ fe25519_square(&t0, t1)
        /* 2^255 - 2^5 */ fe25519_square(&t1, t0)
        /* 2^255 - 21 */ fe25519_mul(&r, t1, z11)
    }

    /// q = 2^255-19
    /// (q-5)/8 = 2^252 - 3
	/// r = x ^ (2^252 - 3)
    static func fe25519_pow2523(_ r: inout fe, _ x: fe) {
        var z2 = fe()
        var z9 = fe()
        var z11 = fe()
        var z2_5_0 = fe()
        var z2_10_0 = fe()
        var z2_20_0 = fe()
        var z2_50_0 = fe()
        var z2_100_0 = fe()
        var t = fe()

        /* 2 */ fe25519_square(&z2, x)
        /* 4 */ fe25519_square(&t, z2)
        /* 8 */ fe25519_square(&t, t)
        /* 9 */ fe25519_mul(&z9, t, x)
        /* 11 */ fe25519_mul(&z11, z9, z2)
        /* 22 */ fe25519_square(&t, z11)
        /* 2^5 - 2^0 = 31 */ fe25519_mul(&z2_5_0, t, z9)

        /* 2^6 - 2^1 */ fe25519_square(&t, z2_5_0)
        /* 2^10 - 2^5 */ for _ in 1..<5 { fe25519_square(&t, t) }
        /* 2^10 - 2^0 */ fe25519_mul(&z2_10_0, t, z2_5_0)

        /* 2^11 - 2^1 */ fe25519_square(&t, z2_10_0)
        /* 2^20 - 2^10 */ for _ in 1..<10 { fe25519_square(&t, t) }
        /* 2^20 - 2^0 */ fe25519_mul(&z2_20_0, t, z2_10_0)

        /* 2^21 - 2^1 */ fe25519_square(&t, z2_20_0)
        /* 2^40 - 2^20 */ for _ in 1..<20 { fe25519_square(&t, t) }
        /* 2^40 - 2^0 */ fe25519_mul(&t, t, z2_20_0)

        /* 2^41 - 2^1 */ fe25519_square(&t, t)
        /* 2^50 - 2^10 */ for _ in 1..<10 { fe25519_square(&t, t) }
        /* 2^50 - 2^0 */ fe25519_mul(&z2_50_0, t, z2_10_0)

        /* 2^51 - 2^1 */ fe25519_square(&t, z2_50_0)
        /* 2^100 - 2^50 */ for _ in 1..<50 { fe25519_square(&t, t) }
        /* 2^100 - 2^0 */ fe25519_mul(&z2_100_0, t, z2_50_0)

        /* 2^101 - 2^1 */ fe25519_square(&t, z2_100_0)
        /* 2^200 - 2^100 */ for _ in 1..<100 { fe25519_square(&t, t) }
        /* 2^200 - 2^0 */ fe25519_mul(&t, t, z2_100_0)

        /* 2^201 - 2^1 */ fe25519_square(&t, t)
        /* 2^250 - 2^50 */ for _ in 1..<50 { fe25519_square(&t, t) }
        /* 2^250 - 2^0 */ fe25519_mul(&t, t, z2_50_0)

        /* 2^251 - 2^1 */ fe25519_square(&t, t)
        /* 2^252 - 2^2 */ fe25519_square(&t, t)
        /* 2^252 - 3 */ fe25519_mul(&r, t, x)
    }
}
