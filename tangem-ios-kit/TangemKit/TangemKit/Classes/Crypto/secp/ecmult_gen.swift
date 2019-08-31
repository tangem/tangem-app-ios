//
//  ecmult_gen.swift
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

struct secp256k1_ecmult_gen_context
{
    /* For accelerating the computation of a*G:
     * To harden against timing attacks, use the following mechanism:
     * * Break up the multiplicand into groups of 4 bits, called n_0, n_1, n_2, ..., n_63.
     * * Compute sum(n_i * 16^i * G + U_i, i=0..63), where:
     *   * U_i = U * 2^i (for i=0..62)
     *   * U_i = U * (1-2^63) (for i=63)
     *   where U is a point with no known corresponding scalar. Note that sum(U_i, i=0..63) = 0.
     * For each i, and each of the 16 possible values of n_i, (n_i * 16^i * G + U_i) is
     * precomputed (call it prec(i, n_i)). The formula now becomes sum(prec(i, n_i), i=0..63).
     * None of the resulting prec group elements have a known scalar, and neither do any of
     * the intermediate sums while computing a*G.
     */
    /* a * G の計算を加速させるため:
     *
     * a: スカラー値
     * G: ベースポイント
     *
     * タイミングアタックを難しくするため、次のようなメカニズムを使う:
     * 被乗数を4bits のグループへ分割し、n_0, n_1, n_2, ..., n_63 と呼ぶ.
     * sum(n_i * 16^i * G + U_i, i=0..63) を計算する. ここで
     * U_i = U * 2^i (for i = 0..62)
     * U_i = U * (1-2^63) (for i = 63)
     * ここで U は、対応するスカラー値が知られていない点である.
     * sum(U_i, i=0..63) = 0 である.
     * 各i と n_i の16個の取りうる各値に対して、(n_i * 16^i * G + U_i)を事前計算しておく.
     * これを prec(i, n_i) と呼ぶ.
     * 式は sum(prec(i, n_i), i=0..63)となる.
     * 結果となるprec群要素のいずれも知られたスカラー値を持っていない.
     * またどの中間の合計値も同様である. a*Gを計算する間.
     */
    //secp256k1_ge_storage (*prec)[64][16]; /* prec[j][i] = 16^j * i * G + U_i */
    var prec: [[secp256k1_ge_storage]]
    var blind: secp256k1_scalar
    var initial: secp256k1_gej
    init(){
        prec = [[secp256k1_ge_storage]]()
        blind = secp256k1_scalar()
        initial = secp256k1_gej()
    }
}
