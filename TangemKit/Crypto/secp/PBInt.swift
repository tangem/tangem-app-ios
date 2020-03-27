//
//  PBInt.swift
//  secp256k1
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018年 pebble8888. All rights reserved.
//

import Foundation

func UInt8ToUInt32LE(
    _ dst: inout [UInt32],
    _ dst_begin: UInt, // by UInt8 size
    _ src: [UInt8],
    _ src_begin: Int,
    _ size: UInt)
{
    var src_idx: Int = src_begin
    while src_idx < src_begin + Int(size) {
        let v = Int(dst_begin) + src_idx - src_begin
        let v4 = v / 4
        let w = v % 4
        switch w {
        case 0:
            dst[v4] = (dst[v4] & 0xffffff00) + UInt32(src[src_idx]) << 0
        case 1:
            dst[v4] = (dst[v4] & 0xffff00ff) + UInt32(src[src_idx]) << 8
        case 2:
            dst[v4] = (dst[v4] & 0xff00ffff) + UInt32(src[src_idx]) << 16
        case 3:
            dst[v4] = (dst[v4] & 0x00ffffff) + UInt32(src[src_idx]) << 24
        default:
            fatalError()
        }
        src_idx += 1
    }
}

func UInt8ToUInt32BE(_ dst: inout [UInt32],
                     _ dst_begin: UInt, // by UInt8 size
    _ src: [UInt8],
    _ src_begin: Int,
    _ size: UInt)
{
    var src_idx = src_begin
    while src_idx < size {
        let v = Int(dst_begin) + src_idx
        let v4 = v/4
        let w = v % 4
        switch w {
        case 3:
            dst[v4] = (dst[v4] & 0xffffff00) + UInt32(src[src_idx])
        case 2:
            dst[v4] = (dst[v4] & 0xffff00ff) + UInt32(src[src_idx]) << 8
        case 1:
            dst[v4] = (dst[v4] & 0xff00ffff) + UInt32(src[src_idx]) << 16
        case 0:
            dst[v4] = (dst[v4] & 0x00ffffff) + UInt32(src[src_idx]) << 24
        default:
            fatalError()
        }
        src_idx += 1
    }
}

func UInt32LEToUInt8(_ dst: inout [UInt8], _ dst_idx: Int, _ src: UInt32)
{
    assert(dst_idx >= 0)
    assert(dst_idx + 3 < dst.count)
    dst[dst_idx]     = UInt8(0xff & src)
    dst[dst_idx + 1] = UInt8(0xff & (src >> 8))
    dst[dst_idx + 2] = UInt8(0xff & (src >> 16))
    dst[dst_idx + 3] = UInt8(0xff & (src >> 24))
}

func UInt32BEToUInt8(_ dst: inout [UInt8], _ dst_idx: Int, _ src: UInt32)
{
    assert(dst_idx >= 0)
    assert(dst_idx + 3 < dst.count)
    dst[dst_idx]     = UInt8(0xff & (src >> 24))
    dst[dst_idx + 1] = UInt8(0xff & (src >> 16))
    dst[dst_idx + 2] = UInt8(0xff & (src >> 8))
    dst[dst_idx + 3] = UInt8(0xff & src)
}

public extension UInt64
{
    var lo: UInt32 {
        return UInt32(self & UInt64(UInt32.max))
    }
    var hi: UInt32 {
        return UInt32((self >> 32) & UInt64(UInt32.max))
    }
}

public extension UInt32
{
    var lo: UInt16 {
        return UInt16(self & UInt32(UInt16.max))
    }
    var hi: UInt16 {
        return UInt16((self >> 16) & UInt32(UInt16.max))
    }
    var ll: UInt8 {
        return UInt8(self & UInt32(0xff))
    }
    var lh: UInt8 {
        return UInt8((self >> 8) & UInt32(0xff))
    }
    var hl: UInt8 {
        return UInt8((self >> 16) & UInt32(0xff))
    }
    var hh: UInt8 {
        return UInt8((self >> 24) & UInt32(0xff))
    }
}

public extension UInt16
{
    var lo: UInt8 {
        return UInt8(self & UInt16(UInt8.max))
    }
    var hi: UInt8 {
        return UInt8((self >> 8) & UInt16(UInt8.max))
    }
}

extension Array where Element == UInt8 {
    public func toLEUInt32() -> [UInt32]? {
        if self.count % 4 != 0 {
            return nil
        }
        let c = Int(self.count / 4)
        var v = [UInt32](repeating: 0, count: c)
        var it = self.makeIterator()
        for i in 0 ..< c {
            guard let a = it.next() else { break }
            v[i] += UInt32(a)
            guard let b = it.next() else { break }
            v[i] += (UInt32(b) << 8)
            guard let c = it.next() else { break }
            v[i] += (UInt32(c) << 16)
            guard let d = it.next() else { break }
            v[i] += (UInt32(d) << 24)
        }
        return v
    }
    
}

extension Array where Element == UInt8 {
    public mutating func fill(_ v: Element){
        var i = self.startIndex
        while i < self.endIndex {
            self[i] = v
            i = self.index(after: i)
        }
    }
    public mutating func fill(_ v: Element, count: Int) {
        var i = self.startIndex
        while i < Swift.min(self.endIndex, self.startIndex + count) {
            self[i] = v
            i = self.index(after: i)
        }
    }
    public mutating func clear() {
        fill(0)
    }
    public mutating func clear(count: Int){
        fill(0, count: count)
    }
}

extension Array where Element == UInt8 {
    public func equal(_ v: Array<Element>) -> Bool {
        if self.count != v.count { return false }
        for i in 0 ..< self.count {
            if self[i] != v[i] { return false }
        }
        return true
    }
    public func equal(index1: Int = 0, _ v: Array<Element>, index2: Int = 0, count: Int) -> Bool {
        if self.count - index1 < count { return false }
        if v.count - index2 < count { return false }
        for i in 0 ..< count {
            if self[index1 + i] != v[index2 + i] { return false }
        }
        return true
    }
    public func compare(index1: Int = 0, _ v: Array<Element>, index2: Int = 0, count: Int) -> Bool {
        if self.count - index1 < count { return false }
        if v.count - index2 < count { return false }
        for i in 0 ..< count {
            if !(self[index1 + i] < v[index2 + i]) { return false }
        }
        return true
    }
    public func is_zero(count: Int) -> Bool {
        if self.count < count { return false }
        for i in 0 ..< count {
            if self[i] != 0 {
                return false
            }
        }
        return true
    }
    
    public func is_zero_first_half() -> Bool {
        if self.count < 32 { return false }
        for i in 0 ..< 32 {
            if self[i] != 0 {
                return false
            }
        }
        return true
    }
    public func is_zero_second_half() -> Bool {
        if self.count < 64 { return false }
        for i in 32 ..< 64 {
            if self[i] != 0 {
                return false
            }
        }
        return true
    }
}

public extension String {
    var toUInt8: [UInt8] {
        let v = self.utf8CString.map({ UInt8($0) })
        return Array(v[0 ..< (v.count-1)])
    }
}
