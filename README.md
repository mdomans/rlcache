# rlcache

A very basic cache server written in Swift. I use caching servers as toy projects to learn about language capabilities.

What is done now:
* uses SwiftNIO as the basis for server
* swift-nio-redis to handle redis protocol
* argument parser for running the server from cmd line
* basic setup for tests + a few tests to see how simple Swift server side apps can be tested
* own version of LFU modified to avoid linked lists and classes, the whole thing is single class and structs/enums beyond

TODO:
* add support for both LFU and LRU
* add support for tracking memory use
* more tests
* benchmarks
* CI server integration
