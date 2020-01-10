all: generate copy

generate:
	protoc --swift_out=. dex.proto

copy:
	cp dex.pb.swift ../../BinanceChain/Sources/Protobuf

