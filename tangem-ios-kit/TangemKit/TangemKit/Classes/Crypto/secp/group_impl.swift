//
//  group_impl.swift
//  secp256k1
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 pebble8888. All rights reserved.
//
/**********************************************************************
 * Copyright (c) 2013, 2014 Pieter Wuille                             *
 * Distributed under the MIT software license, see the accompanying   *
 * file COPYING or http://www.opensource.org/licenses/mit-license.php.*
 **********************************************************************/

import Foundation

/* These points can be generated in sage as follows:
 *
 * 0. Setup a worksheet with the following parameters.
 *   b = 4  # whatever CURVE_B will be set to
 *   F = FiniteField (0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F)
 *   C = EllipticCurve ([F (0), F (b)])
 *
 * 1. Determine all the small orders available to you. (If there are
 *    no satisfactory ones, go back and change b.)
 *   print C.order().factor(limit=1000)
 *
 * 2. Choose an order as one of the prime factors listed in the above step.
 *    (You can also multiply some to get a composite order, though the
 *    tests will crash trying to invert scalars during signing.) We take a
 *    random point and scale it to drop its order to the desired value.
 *    There is some probability this won't work; just try again.
 *   order = 199
 *   P = C.random_point()
 *   P = (int(P.order()) / int(order)) * P
 *   assert(P.order() == order)
 *
 * 3. Print the values. You'll need to use a vim macro or something to
 *    split the hex output into 4-byte chunks.
 *   print "%x %x" % P.xy()
 */
/** Generator for secp256k1, value 'g' defined in
 *  "Standards for Efficient Cryptography" (SEC2) 2.7.1.
 *
 *  @note base point G
 */
let secp256k1_ge_const_g: secp256k1_ge = SECP256K1_GE_CONST(
    // x
    0x79BE667E, 0xF9DCBBAC, 0x55A06295, 0xCE870B07,
    0x029BFCDB, 0x2DCE28D9, 0x59F2815B, 0x16F81798,
    // y
    0x483ADA77, 0x26A3C465, 0x5DA4FBFC, 0x0E1108A8,
    0xFD17B448, 0xA6855419, 0x9C47D08F, 0xFB10D4B8
);

// y ^ 2 = x ^ 3 + CURVE_B
let CURVE_B: UInt32 = 7

func secp256k1_ge_set_gej_zinv(_ r: inout secp256k1_ge, _ a: secp256k1_gej, _ zi: secp256k1_fe) {
    var zi2 = secp256k1_fe()
    var zi3 = secp256k1_fe()
    secp256k1_fe_sqr(&zi2, zi);
    secp256k1_fe_mul(&zi3, zi2, zi);
    secp256k1_fe_mul(&r.x, a.x, zi2);
    secp256k1_fe_mul(&r.y, a.y, zi3);
    r.infinity = a.infinity;
}

func secp256k1_ge_set_xy(_ r: inout secp256k1_ge, _ x: secp256k1_fe, _ y: secp256k1_fe) {
    r.infinity = false
    r.x = x;
    r.y = y;
}

func secp256k1_ge_is_infinity(_ a: secp256k1_ge) -> Bool {
    return a.infinity;
}

func secp256k1_ge_neg(_ r: inout secp256k1_ge, _ a: secp256k1_ge) {
    r = a;
    secp256k1_fe_normalize_weak(&r.y);
    secp256k1_fe_negate(&r.y, r.y, 1);
}

func secp256k1_ge_set_gej(_ r: inout secp256k1_ge, _ a: inout secp256k1_gej) {
    var z2 = secp256k1_fe()
    var z3 = secp256k1_fe()
    r.infinity = a.infinity;
    secp256k1_fe_inv(&a.z, a.z);
    secp256k1_fe_sqr(&z2, a.z);
    secp256k1_fe_mul(&z3, a.z, z2);
    secp256k1_fe_mul(&a.x, a.x, z2);
    secp256k1_fe_mul(&a.y, a.y, z3);
    secp256k1_fe_set_int(&a.z, 1);
    r.x = a.x;
    r.y = a.y;
}

func secp256k1_ge_set_gej_var(_ r: inout secp256k1_ge, _ a: inout secp256k1_gej) {
    var z2 = secp256k1_fe()
    var z3 = secp256k1_fe()
    r.infinity = a.infinity;
    if (a.infinity) {
        return;
    }
    secp256k1_fe_inv_var(&a.z, a.z);
    secp256k1_fe_sqr(&z2, a.z);
    secp256k1_fe_mul(&z3, a.z, z2);
    secp256k1_fe_mul(&a.x, a.x, z2);
    secp256k1_fe_mul(&a.y, a.y, z3);
    secp256k1_fe_set_int(&a.z, 1);
    r.x = a.x;
    r.y = a.y;
}

func secp256k1_ge_set_all_gej_var(_ r: inout [secp256k1_ge], _ a: [secp256k1_gej], _ len: UInt, _ cb: secp256k1_callback?) {
    var az: [secp256k1_fe]
    var azi: [secp256k1_fe]
    var count: Int = 0
    az = [secp256k1_fe](repeating: secp256k1_fe(), count: Int(len))
    for i in 0..<Int(len) {
        if (!a[i].infinity) {
            az[count] = a[i].z;
            count += 1
        }
    }
    
    //azi = (secp256k1_fe *)checked_malloc(cb, sizeof(secp256k1_fe) * count);
    azi = [secp256k1_fe](repeating: secp256k1_fe(), count: count)
    secp256k1_fe_inv_all_var(&azi, az, UInt(count));
    //free(az);
    
    count = 0;
    for i in 0..<Int(len) {
        r[i].infinity = a[i].infinity;
        if (!a[i].infinity) {
            secp256k1_ge_set_gej_zinv(&r[i], a[i], azi[count]);
            count += 1
        }
    }
    //free(azi);
}

func secp256k1_ge_set_table_gej_var(_ r: inout [secp256k1_ge], _ a: [secp256k1_gej], _ zr: [secp256k1_fe], _ len: UInt) {
    var i: Int = Int(len) - 1
    var zi = secp256k1_fe()
    
    if (len > 0) {
        /* Compute the inverse of the last z coordinate, and use it to compute the last affine output. */
        secp256k1_fe_inv(&zi, a[i].z);
        secp256k1_ge_set_gej_zinv(&r[i], a[i], zi);
        
        /* Work out way backwards, using the z-ratios to scale the x/y values. */
        while (i > 0) {
            secp256k1_fe_mul(&zi, zi, zr[i]);
            i -= 1
            secp256k1_ge_set_gej_zinv(&r[i], a[i], zi);
        }
    }
}

func secp256k1_ge_globalz_set_table_gej(_ len: UInt, _ r: inout [secp256k1_ge], _ globalz: inout secp256k1_fe, _ a: [secp256k1_gej], _ zr: [secp256k1_fe]) {
    var i: Int = Int(len) - 1
    var zs: secp256k1_fe
    
    if (len > 0) {
        /* The z of the final point gives us the "global Z" for the table. */
        r[i].x = a[i].x;
        r[i].y = a[i].y;
        globalz = a[i].z;
        r[i].infinity = false
        zs = zr[i];
        
        /* Work our way backwards, using the z-ratios to scale the x/y values. */
        while (i > 0) {
            if (i != len - 1) {
                secp256k1_fe_mul(&zs, zs, zr[i]);
            }
            i -= 1
            secp256k1_ge_set_gej_zinv(&r[i], a[i], zs);
        }
    }
}

// set yacobian O
func secp256k1_gej_set_infinity(_ r: inout secp256k1_gej) {
    r.infinity = true
    secp256k1_fe_clear(&r.x);
    secp256k1_fe_clear(&r.y);
    secp256k1_fe_clear(&r.z);
}

// set yacobian O
func secp256k1_gej_clear(_ r: inout secp256k1_gej) {
    r.infinity = false
    secp256k1_fe_clear(&r.x);
    secp256k1_fe_clear(&r.y);
    secp256k1_fe_clear(&r.z);
}

// set yacobian O
func secp256k1_ge_clear(_ r: inout secp256k1_ge) {
    r.infinity = false
    secp256k1_fe_clear(&r.x);
    secp256k1_fe_clear(&r.y);
}

//
func secp256k1_ge_set_xquad(_ r: inout secp256k1_ge, _ x: secp256k1_fe) -> Bool {
    var x2 = secp256k1_fe()
    var x3 = secp256k1_fe()
    var c = secp256k1_fe()
    r.x = x
    secp256k1_fe_sqr(&x2, x);
    secp256k1_fe_mul(&x3, x, x2);
    r.infinity = false
    secp256k1_fe_set_int(&c, CURVE_B);
    secp256k1_fe_add(&c, x3);
    return secp256k1_fe_sqrt(&r.y, c);
}

//
func secp256k1_ge_set_xo_var(_ r: inout secp256k1_ge, _ x: secp256k1_fe, _ odd: Bool) -> Bool {
    if (!secp256k1_ge_set_xquad(&r, x)) {
        return false
    }
    secp256k1_fe_normalize_var(&r.y);
    if (secp256k1_fe_is_odd(r.y) != odd) {
        secp256k1_fe_negate(&r.y, r.y, 1);
    }
    return true
}

// transform affine point to z=1 yacobian point
func secp256k1_gej_set_ge(_ r: inout secp256k1_gej, _ a: secp256k1_ge) {
    r.infinity = a.infinity;
    r.x = a.x;
    r.y = a.y;
    secp256k1_fe_set_int(&r.z, 1)
}

// is equal yacobian a to affince x point
func secp256k1_gej_eq_x_var(_ x: secp256k1_fe, _ a: secp256k1_gej) -> Bool {
    var r = secp256k1_fe()
    var r2 = secp256k1_fe()
    VERIFY_CHECK(!a.infinity);
    secp256k1_fe_sqr(&r, a.z); secp256k1_fe_mul(&r, r, x);
    r2 = a.x; secp256k1_fe_normalize_weak(&r2);
    return secp256k1_fe_equal_var(r, r2);
}

func secp256k1_gej_neg(_ r: inout secp256k1_gej, _ a: secp256k1_gej) {
    r.infinity = a.infinity;
    r.x = a.x;
    r.y = a.y;
    r.z = a.z;
    secp256k1_fe_normalize_weak(&r.y);
    secp256k1_fe_negate(&r.y, r.y, 1);
}

// is yacobian O
func secp256k1_gej_is_infinity(_ a: secp256k1_gej) -> Bool {
    return a.infinity;
}

func secp256k1_gej_is_valid_var(_ a: secp256k1_gej) -> Bool {
    var y2 = secp256k1_fe()
    var x3 = secp256k1_fe()
    var z2 = secp256k1_fe()
    var z6 = secp256k1_fe()
    if (a.infinity) {
        return false
    }
    /** y^2 = x^3 + 7
     *  (Y/Z^3)^2 = (X/Z^2)^3 + 7
     *  Y^2 / Z^6 = X^3 / Z^6 + 7
     *  Y^2 = X^3 + 7*Z^6
     */
    secp256k1_fe_sqr(&y2, a.y);
    secp256k1_fe_sqr(&x3, a.x); secp256k1_fe_mul(&x3, x3, a.x);
    secp256k1_fe_sqr(&z2, a.z);
    secp256k1_fe_sqr(&z6, z2); secp256k1_fe_mul(&z6, z6, z2);
    secp256k1_fe_mul_int(&z6, CURVE_B);
    secp256k1_fe_add(&x3, z6);
    secp256k1_fe_normalize_weak(&x3);
    return secp256k1_fe_equal_var(y2, x3);
}

//
func secp256k1_ge_is_valid_var(_ a: secp256k1_ge) -> Bool {
    var y2 = secp256k1_fe()
    var x3 = secp256k1_fe()
    var c = secp256k1_fe()
    if (a.infinity) {
        return false
    }
    /* y^2 = x^3 + 7 */
    secp256k1_fe_sqr(&y2, a.y);
    secp256k1_fe_sqr(&x3, a.x); secp256k1_fe_mul(&x3, x3, a.x);
    secp256k1_fe_set_int(&c, CURVE_B);
    secp256k1_fe_add(&x3, c);
    secp256k1_fe_normalize_weak(&x3);
    return secp256k1_fe_equal_var(y2, x3);
}

// r = 2 * a
// [REDACTED_USERNAME] r  : gej
// [REDACTED_USERNAME] a  : gej
// [REDACTED_USERNAME] rzr: fe
func secp256k1_gej_double_var(_ r: inout secp256k1_gej, _ a: secp256k1_gej, _ rzr: inout secp256k1_fe) {
    /* Operations: 3 mul, 4 sqr, 0 normalize, 12 mul_int/add/negate.
     *
     * Note that there is an implementation described at
     *     https://hyperelliptic.org/EFD/g1p/auto-shortw-jacobian-0.html#doubling-dbl-2009-l
     * which trades a multiply for a square, but in practice this is actually slower,
     * mainly because it requires more normalizations.
     */
    var t1 = secp256k1_fe()
    var t2 = secp256k1_fe()
    var t3 = secp256k1_fe()
    var t4 = secp256k1_fe()
    /** For secp256k1, 2Q is infinity if and only if Q is infinity. This is because if 2Q = infinity,
     *  Q must equal -Q, or that Q.y == -(Q.y), or Q.y is 0. For a point on y^2 = x^3 + 7 to have
     *  y=0, x^3 must be -7 mod p. However, -7 has no cube root mod p.
     *
     *  Having said this, if this function receives a point on a sextic twist, e.g. by
     *  a fault attack, it is possible for y to be 0. This happens for y^2 = x^3 + 6,
     *  since -6 does have a cube root mod p. For this point, this function will not set
     *  the infinity flag even though the point doubles to infinity, and the result
     *  point will be gibberish (z = 0 but infinity = 0).
     */
    r.infinity = a.infinity;
    if (r.infinity) {
        //if (rzr != nil) {
            secp256k1_fe_set_int(&rzr, 1);
        //}
        return;
    }
    
    //if (rzr != nil) {
        rzr = a.y;
        secp256k1_fe_normalize_weak(&rzr);
        secp256k1_fe_mul_int(&rzr, 2);
    //}
    
    secp256k1_fe_mul(&r.z, a.z, a.y);
    secp256k1_fe_mul_int(&r.z, 2);       /* Z' = 2*Y*Z (2) */
    secp256k1_fe_sqr(&t1, a.x);
    secp256k1_fe_mul_int(&t1, 3);         /* T1 = 3*X^2 (3) */
    secp256k1_fe_sqr(&t2, t1);           /* T2 = 9*X^4 (1) */
    secp256k1_fe_sqr(&t3, a.y);
    secp256k1_fe_mul_int(&t3, 2);         /* T3 = 2*Y^2 (2) */
    secp256k1_fe_sqr(&t4, t3);
    secp256k1_fe_mul_int(&t4, 2);         /* T4 = 8*Y^4 (2) */
    secp256k1_fe_mul(&t3, t3, a.x);    /* T3 = 2*X*Y^2 (1) */
    r.x = t3;
    secp256k1_fe_mul_int(&r.x, 4);       /* X' = 8*X*Y^2 (4) */
    secp256k1_fe_negate(&r.x, r.x, 4); /* X' = -8*X*Y^2 (5) */
    secp256k1_fe_add(&r.x, t2);         /* X' = 9*X^4 - 8*X*Y^2 (6) */
    secp256k1_fe_negate(&t2, t2, 1);     /* T2 = -9*X^4 (2) */
    secp256k1_fe_mul_int(&t3, 6);         /* T3 = 12*X*Y^2 (6) */
    secp256k1_fe_add(&t3, t2);           /* T3 = 12*X*Y^2 - 9*X^4 (8) */
    secp256k1_fe_mul(&r.y, t1, t3);    /* Y' = 36*X^3*Y^2 - 27*X^6 (1) */
    secp256k1_fe_negate(&t2, t4, 2);     /* T2 = -8*Y^4 (3) */
    secp256k1_fe_add(&r.y, t2);         /* Y' = 36*X^3*Y^2 - 27*X^6 - 8*Y^4 (4) */
}

// r = 2 * a for a is not O
// r  : gej
// a  : gej
// rzr: fe
func secp256k1_gej_double_nonzero(_ r: inout secp256k1_gej, _ a: secp256k1_gej, _ rzr: inout secp256k1_fe) {
    VERIFY_CHECK(!secp256k1_gej_is_infinity(a));
    secp256k1_gej_double_var(&r, a, &rzr);
}

// r = a + b
// r  : gej
// a  : gej
// b  : gej
// rzr: fe
func secp256k1_gej_add_var(_ r: inout secp256k1_gej, _ a: secp256k1_gej, _ b: secp256k1_gej, _ rzr: inout secp256k1_fe) {
    /* Operations: 12 mul, 4 sqr, 2 normalize, 12 mul_int/add/negate */
    var z22 = secp256k1_fe()
    var z12 = secp256k1_fe()
    var u1 = secp256k1_fe()
    var u2 = secp256k1_fe()
    var s1 = secp256k1_fe()
    var s2 = secp256k1_fe()
    var h = secp256k1_fe()
    var i = secp256k1_fe()
    var i2 = secp256k1_fe()
    var h2 = secp256k1_fe()
    var h3 = secp256k1_fe()
    var t = secp256k1_fe()
    
    if (a.infinity) {
        //VERIFY_CHECK(rzr == NULL);
        r = b;
        return;
    }
    
    if (b.infinity) {
        //if (rzr != nil) {
            secp256k1_fe_set_int(&rzr, 1);
        //}
        r = a;
        return;
    }
    
    r.infinity = false
    secp256k1_fe_sqr(&z22, b.z);
    secp256k1_fe_sqr(&z12, a.z);
    secp256k1_fe_mul(&u1, a.x, z22);
    secp256k1_fe_mul(&u2, b.x, z12);
    secp256k1_fe_mul(&s1, a.y, z22); secp256k1_fe_mul(&s1, s1, b.z);
    secp256k1_fe_mul(&s2, b.y, z12); secp256k1_fe_mul(&s2, s2, a.z);
    secp256k1_fe_negate(&h, u1, 1); secp256k1_fe_add(&h, u2);
    secp256k1_fe_negate(&i, s1, 1); secp256k1_fe_add(&i, s2);
    if (secp256k1_fe_normalizes_to_zero_var(&h)) {
        if (secp256k1_fe_normalizes_to_zero_var(&i)) {
            secp256k1_gej_double_var(&r, a, &rzr);
        } else {
            //if (rzr != nil) {
                secp256k1_fe_set_int(&rzr, 0);
            //}
            r.infinity = true
        }
        return;
    }
    secp256k1_fe_sqr(&i2, i);
    secp256k1_fe_sqr(&h2, h);
    secp256k1_fe_mul(&h3, h, h2);
    secp256k1_fe_mul(&h, h, b.z);
    //if (rzr != nil) {
        rzr = h;
    //}
    secp256k1_fe_mul(&r.z, a.z, h);
    secp256k1_fe_mul(&t, u1, h2);
    r.x = t; secp256k1_fe_mul_int(&r.x, 2); secp256k1_fe_add(&r.x, h3); secp256k1_fe_negate(&r.x, r.x, 3); secp256k1_fe_add(&r.x, i2);
    secp256k1_fe_negate(&r.y, r.x, 5); secp256k1_fe_add(&r.y, t); secp256k1_fe_mul(&r.y, r.y, i);
    secp256k1_fe_mul(&h3, h3, s1); secp256k1_fe_negate(&h3, h3, 1);
    secp256k1_fe_add(&r.y, h3);
}

// r = a + b
// r  : gej
// a  : gej
// b  : ge
// rzr: fe
func secp256k1_gej_add_ge_var(_ r: inout secp256k1_gej, _ a: secp256k1_gej, _ b: secp256k1_ge, _ rzr: inout secp256k1_fe) {
    /* 8 mul, 3 sqr, 4 normalize, 12 mul_int/add/negate */
    var z12 = secp256k1_fe()
    var u1 = secp256k1_fe()
    var u2 = secp256k1_fe()
    var s1 = secp256k1_fe()
    var s2 = secp256k1_fe()
    var h = secp256k1_fe()
    var i = secp256k1_fe()
    var i2 = secp256k1_fe()
    var h2 = secp256k1_fe()
    var h3 = secp256k1_fe()
    var t = secp256k1_fe()
    if (a.infinity) {
        //VERIFY_CHECK(rzr == NULL);
        secp256k1_gej_set_ge(&r, b);
        return;
    }
    if (b.infinity) {
        //if (rzr != nil) {
            secp256k1_fe_set_int(&rzr, 1);
        //}
        r = a;
        return;
    }
    r.infinity = false
    
    secp256k1_fe_sqr(&z12, a.z);
    u1 = a.x; secp256k1_fe_normalize_weak(&u1);
    secp256k1_fe_mul(&u2, b.x, z12);
    s1 = a.y; secp256k1_fe_normalize_weak(&s1);
    secp256k1_fe_mul(&s2, b.y, z12); secp256k1_fe_mul(&s2, s2, a.z);
    secp256k1_fe_negate(&h, u1, 1); secp256k1_fe_add(&h, u2);
    secp256k1_fe_negate(&i, s1, 1); secp256k1_fe_add(&i, s2);
    if (secp256k1_fe_normalizes_to_zero_var(&h)) {
        if (secp256k1_fe_normalizes_to_zero_var(&i)) {
            secp256k1_gej_double_var(&r, a, &rzr);
        } else {
            //if (rzr != nil) {
                secp256k1_fe_set_int(&rzr, 0);
            //}
            r.infinity = true
        }
        return
    }
    secp256k1_fe_sqr(&i2, i);
    secp256k1_fe_sqr(&h2, h);
    secp256k1_fe_mul(&h3, h, h2);
    //if (rzr != nil) {
        rzr = h;
    //}
    secp256k1_fe_mul(&r.z, a.z, h);
    secp256k1_fe_mul(&t, u1, h2);
    r.x = t; secp256k1_fe_mul_int(&r.x, 2); secp256k1_fe_add(&r.x, h3); secp256k1_fe_negate(&r.x, r.x, 3); secp256k1_fe_add(&r.x, i2);
    secp256k1_fe_negate(&r.y, r.x, 5); secp256k1_fe_add(&r.y, t); secp256k1_fe_mul(&r.y, r.y, i);
    secp256k1_fe_mul(&h3, h3, s1); secp256k1_fe_negate(&h3, h3, 1);
    secp256k1_fe_add(&r.y, h3);
}

//
// r     : gej
// a     : gej
// b     : ge
// bzinv : fe
func secp256k1_gej_add_zinv_var(_ r: inout secp256k1_gej, _ a: secp256k1_gej, _ b: secp256k1_ge, _ bzinv: secp256k1_fe) {
    /* 9 mul, 3 sqr, 4 normalize, 12 mul_int/add/negate */
    var az = secp256k1_fe()
    var z12 = secp256k1_fe()
    var u1 = secp256k1_fe()
    var u2 = secp256k1_fe()
    var s1 = secp256k1_fe()
    var s2 = secp256k1_fe()
    var h = secp256k1_fe()
    var i = secp256k1_fe()
    var i2 = secp256k1_fe()
    var h2 = secp256k1_fe()
    var h3 = secp256k1_fe()
    var t = secp256k1_fe()
   
    if (b.infinity) {
        r = a;
        return;
    }
    if (a.infinity) {
        var bzinv2 = secp256k1_fe()
        var bzinv3 = secp256k1_fe()
        r.infinity = b.infinity;
        secp256k1_fe_sqr(&bzinv2, bzinv);
        secp256k1_fe_mul(&bzinv3, bzinv2, bzinv);
        secp256k1_fe_mul(&r.x, b.x, bzinv2);
        secp256k1_fe_mul(&r.y, b.y, bzinv3);
        secp256k1_fe_set_int(&r.z, 1);
        return;
    }
    r.infinity = false
    
    /** We need to calculate (rx,ry,rz) = (ax,ay,az) + (bx,by,1/bzinv). Due to
     *  secp256k1's isomorphism we can multiply the Z coordinates on both sides
     *  by bzinv, and get: (rx,ry,rz*bzinv) = (ax,ay,az*bzinv) + (bx,by,1).
     *  This means that (rx,ry,rz) can be calculated as
     *  (ax,ay,az*bzinv) + (bx,by,1), when not applying the bzinv factor to rz.
     *  The variable az below holds the modified Z coordinate for a, which is used
     *  for the computation of rx and ry, but not for rz.
     */
    secp256k1_fe_mul(&az, a.z, bzinv);
    
    secp256k1_fe_sqr(&z12, az);
    u1 = a.x; secp256k1_fe_normalize_weak(&u1);
    secp256k1_fe_mul(&u2, b.x, z12);
    s1 = a.y; secp256k1_fe_normalize_weak(&s1);
    secp256k1_fe_mul(&s2, b.y, z12); secp256k1_fe_mul(&s2, s2, az);
    secp256k1_fe_negate(&h, u1, 1); secp256k1_fe_add(&h, u2);
    secp256k1_fe_negate(&i, s1, 1); secp256k1_fe_add(&i, s2);
    if (secp256k1_fe_normalizes_to_zero_var(&h)) {
        if (secp256k1_fe_normalizes_to_zero_var(&i)) {
            var dummy = secp256k1_fe()
            secp256k1_gej_double_var(&r, a, &dummy)
        } else {
            r.infinity = true
        }
        return;
    }
    secp256k1_fe_sqr(&i2, i);
    secp256k1_fe_sqr(&h2, h);
    secp256k1_fe_mul(&h3, h, h2);
    r.z = a.z; secp256k1_fe_mul(&r.z, r.z, h);
    secp256k1_fe_mul(&t, u1, h2);
    r.x = t; secp256k1_fe_mul_int(&r.x, 2); secp256k1_fe_add(&r.x, h3); secp256k1_fe_negate(&r.x, r.x, 3); secp256k1_fe_add(&r.x, i2);
    secp256k1_fe_negate(&r.y, r.x, 5); secp256k1_fe_add(&r.y, t); secp256k1_fe_mul(&r.y, r.y, i);
    secp256k1_fe_mul(&h3, h3, s1); secp256k1_fe_negate(&h3, h3, 1);
    secp256k1_fe_add(&r.y, h3);
}

//
// r : gej
// a : gej
// b : ge
func secp256k1_gej_add_ge(_ r: inout secp256k1_gej, _ a: secp256k1_gej, _ b: secp256k1_ge) {
    /* Operations: 7 mul, 5 sqr, 4 normalize, 21 mul_int/add/negate/cmov */
    let fe_1: secp256k1_fe = SECP256K1_FE_CONST(0, 0, 0, 0, 0, 0, 0, 1);
    var zz = secp256k1_fe()
    var u1 = secp256k1_fe()
    var u2 = secp256k1_fe()
    var s1 = secp256k1_fe()
    var s2 = secp256k1_fe()
    var t = secp256k1_fe()
    var tt = secp256k1_fe()
    var m = secp256k1_fe()
    var n = secp256k1_fe()
    var q = secp256k1_fe()
    var rr = secp256k1_fe()
    var m_alt = secp256k1_fe()
    var rr_alt = secp256k1_fe()
    var infinity: Bool
    var degenerate: Bool
    VERIFY_CHECK(!b.infinity);
    //VERIFY_CHECK(a.infinity == 0 || a.infinity == 1);
    
    /** In:
     *    Eric Brier and Marc Joye, Weierstrass Elliptic Curves and Side-Channel Attacks.
     *    In D. Naccache and P. Paillier, Eds., Public Key Cryptography, vol. 2274 of Lecture Notes in Computer Science, pages 335-345. Springer-Verlag, 2002.
     *  we find as solution for a unified addition/doubling formula:
     *    lambda = ((x1 + x2)^2 - x1 * x2 + a) / (y1 + y2), with a = 0 for secp256k1's curve equation.
     *    x3 = lambda^2 - (x1 + x2)
     *    2*y3 = lambda * (x1 + x2 - 2 * x3) - (y1 + y2).
     *
     *  Substituting x_i = Xi / Zi^2 and yi = Yi / Zi^3, for i=1,2,3, gives:
     *    U1 = X1*Z2^2, U2 = X2*Z1^2
     *    S1 = Y1*Z2^3, S2 = Y2*Z1^3
     *    Z = Z1*Z2
     *    T = U1+U2
     *    M = S1+S2
     *    Q = T*M^2
     *    R = T^2-U1*U2
     *    X3 = 4*(R^2-Q)
     *    Y3 = 4*(R*(3*Q-2*R^2)-M^4)
     *    Z3 = 2*M*Z
     *  (Note that the paper uses xi = Xi / Zi and yi = Yi / Zi instead.)
     *
     *  This formula has the benefit of being the same for both addition
     *  of distinct points and doubling. However, it breaks down in the
     *  case that either point is infinity, or that y1 = -y2. We handle
     *  these cases in the following ways:
     *
     *    - If b is infinity we simply bail by means of a VERIFY_CHECK.
     *
     *    - If a is infinity, we detect this, and at the end of the
     *      computation replace the result (which will be meaningless,
     *      but we compute to be constant-time) with b.x : b.y : 1.
     *
     *    - If a = -b, we have y1 = -y2, which is a degenerate case.
     *      But here the answer is infinity, so we simply set the
     *      infinity flag of the result, overriding the computed values
     *      without even needing to cmov.
     *
     *    - If y1 = -y2 but x1 != x2, which does occur thanks to certain
     *      properties of our curve (specifically, 1 has nontrivial cube
     *      roots in our field, and the curve equation has no x coefficient)
     *      then the answer is not infinity but also not given by the above
     *      equation. In this case, we cmov in place an alternate expression
     *      for lambda. Specifically (y1 - y2)/(x1 - x2). Where both these
     *      expressions for lambda are defined, they are equal, and can be
     *      obtained from each other by multiplication by (y1 + y2)/(y1 + y2)
     *      then substitution of x^3 + 7 for y^2 (using the curve equation).
     *      For all pairs of nonzero points (a, b) at least one is defined,
     *      so this covers everything.
     */
    
    secp256k1_fe_sqr(&zz, a.z);                       /* z = Z1^2 */
    u1 = a.x; secp256k1_fe_normalize_weak(&u1);        /* u1 = U1 = X1*Z2^2 (1) */
    secp256k1_fe_mul(&u2, b.x, zz);                  /* u2 = U2 = X2*Z1^2 (1) */
    s1 = a.y; secp256k1_fe_normalize_weak(&s1);        /* s1 = S1 = Y1*Z2^3 (1) */
    secp256k1_fe_mul(&s2, b.y, zz);                  /* s2 = Y2*Z1^2 (1) */
    secp256k1_fe_mul(&s2, s2, a.z);                  /* s2 = S2 = Y2*Z1^3 (1) */
    t = u1; secp256k1_fe_add(&t, u2);                  /* t = T = U1+U2 (2) */
    m = s1; secp256k1_fe_add(&m, s2);                  /* m = M = S1+S2 (2) */
    secp256k1_fe_sqr(&rr, t);                          /* rr = T^2 (1) */
    secp256k1_fe_negate(&m_alt, u2, 1);                /* Malt = -X2*Z1^2 */
    secp256k1_fe_mul(&tt, u1, m_alt);                 /* tt = -U1*U2 (2) */
    secp256k1_fe_add(&rr, tt);                         /* rr = R = T^2-U1*U2 (3) */
    /** If lambda = R/M = 0/0 we have a problem (except in the "trivial"
     *  case that Z = z1z2 = 0, and this is special-cased later on). */
    degenerate = secp256k1_fe_normalizes_to_zero(&m) &&
                 secp256k1_fe_normalizes_to_zero(&rr);
    /* This only occurs when y1 == -y2 and x1^3 == x2^3, but x1 != x2.
     * This means either x1 == beta*x2 or beta*x1 == x2, where beta is
     * a nontrivial cube root of one. In either case, an alternate
     * non-indeterminate expression for lambda is (y1 - y2)/(x1 - x2),
     * so we set R/M equal to this. */
    rr_alt = s1;
    secp256k1_fe_mul_int(&rr_alt, 2);       /* rr = Y1*Z2^3 - Y2*Z1^3 (2) */
    secp256k1_fe_add(&m_alt, u1);          /* Malt = X1*Z2^2 - X2*Z1^2 */
    
    secp256k1_fe_cmov(&rr_alt, rr, !degenerate);
    secp256k1_fe_cmov(&m_alt, m, !degenerate);
    /* Now Ralt / Malt = lambda and is guaranteed not to be 0/0.
     * From here on out Ralt and Malt represent the numerator
     * and denominator of lambda; R and M represent the explicit
     * expressions x1^2 + x2^2 + x1x2 and y1 + y2. */
    secp256k1_fe_sqr(&n, m_alt);                       /* n = Malt^2 (1) */
    secp256k1_fe_mul(&q, n, t);                       /* q = Q = T*Malt^2 (1) */
    /* These two lines use the observation that either M == Malt or M == 0,
     * so M^3 * Malt is either Malt^4 (which is computed by squaring), or
     * zero (which is "computed" by cmov). So the cost is one squaring
     * versus two multiplications. */
    secp256k1_fe_sqr(&n, n);
    secp256k1_fe_cmov(&n, m, degenerate);              /* n = M^3 * Malt (2) */
    secp256k1_fe_sqr(&t, rr_alt);                      /* t = Ralt^2 (1) */
    secp256k1_fe_mul(&r.z, a.z, m_alt);             /* r.z = Malt*Z (1) */
    infinity = secp256k1_fe_normalizes_to_zero(&r.z) && !a.infinity // * (1 - a.infinity);
    secp256k1_fe_mul_int(&r.z, 2);                     /* r.z = Z3 = 2*Malt*Z (2) */
    secp256k1_fe_negate(&q, q, 1);                     /* q = -Q (2) */
    secp256k1_fe_add(&t, q);                           /* t = Ralt^2-Q (3) */
    secp256k1_fe_normalize_weak(&t);
    r.x = t;                                           /* r.x = Ralt^2-Q (1) */
    secp256k1_fe_mul_int(&t, 2);                        /* t = 2*x3 (2) */
    secp256k1_fe_add(&t, q);                           /* t = 2*x3 - Q: (4) */
    secp256k1_fe_mul(&t, t, rr_alt);                  /* t = Ralt*(2*x3 - Q) (1) */
    secp256k1_fe_add(&t, n);                           /* t = Ralt*(2*x3 - Q) + M^3*Malt (3) */
    secp256k1_fe_negate(&r.y, t, 3);                  /* r.y = Ralt*(Q - 2x3) - M^3*Malt (4) */
    secp256k1_fe_normalize_weak(&r.y);
    secp256k1_fe_mul_int(&r.x, 4);                     /* r.x = X3 = 4*(Ralt^2-Q) */
    secp256k1_fe_mul_int(&r.y, 4);                     /* r.y = Y3 = 4*Ralt*(Q - 2x3) - 4*M^3*Malt (4) */
    
    /** In case a.infinity == 1, replace r with (b.x, b.y, 1). */
    secp256k1_fe_cmov(&r.x, b.x, a.infinity);
    secp256k1_fe_cmov(&r.y, b.y, a.infinity);
    secp256k1_fe_cmov(&r.z, fe_1, a.infinity);
    r.infinity = infinity;
}

// r : gej
// s : fe
func secp256k1_gej_rescale(_ r: inout secp256k1_gej, _ s: secp256k1_fe) {
    /* Operations: 4 mul, 1 sqr */
    var zz = secp256k1_fe()
    VERIFY_CHECK(!secp256k1_fe_is_zero(s));
    secp256k1_fe_sqr(&zz, s);
    secp256k1_fe_mul(&r.x, r.x, zz);                /* r.x *= s^2 */
    secp256k1_fe_mul(&r.y, r.y, zz);
    secp256k1_fe_mul(&r.y, r.y, s);                  /* r.y *= s^3 */
    secp256k1_fe_mul(&r.z, r.z, s);                  /* r.z *= s   */
}

// r : ge_storage
// a : ge
func secp256k1_ge_to_storage(_ r: inout secp256k1_ge_storage, _ a: secp256k1_ge) {
    var x: secp256k1_fe
    var y: secp256k1_fe
    VERIFY_CHECK(!a.infinity);
    x = a.x;
    secp256k1_fe_normalize(&x);
    y = a.y;
    secp256k1_fe_normalize(&y);
    secp256k1_fe_to_storage(&r.x, x);
    secp256k1_fe_to_storage(&r.y, y);
}

// r : ge
// a : ge_storage
func secp256k1_ge_from_storage(_ r: inout secp256k1_ge, _ a: secp256k1_ge_storage) {
    secp256k1_fe_from_storage(&r.x, a.x);
    secp256k1_fe_from_storage(&r.y, a.y);
    r.infinity = false
}

// r : ge_storage
// a : ge_storage
// flag : int
func secp256k1_ge_storage_cmov(_ r: inout secp256k1_ge_storage, _ a: secp256k1_ge_storage, _ flag: Bool) {
    secp256k1_fe_storage_cmov(&r.x, a.x, flag);
    secp256k1_fe_storage_cmov(&r.y, a.y, flag);
}

func secp256k1_gej_has_quad_y_var(_ a: secp256k1_gej) -> Bool {
    var yz = secp256k1_fe()
    
    if (a.infinity) {
        return false
    }
    
    /* We rely on the fact that the Jacobi symbol of 1 / a.z^3 is the same as
     * that of a.z. Thus a.y / a.z^3 is a quadratic residue iff a.y * a.z
     is */
    secp256k1_fe_mul(&yz, a.y, a.z);
    return secp256k1_fe_is_quad_var(yz);
}
