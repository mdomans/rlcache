import XCTest
import class Foundation.Bundle
@testable import rlcache

class keystoreTests: XCTestCase {
    let testData = "b".data(using: .utf8)!

    func testLFU() throws {
        let lfu = LFU(max_size: 10)
        lfu.set(key: "a", value: self.testData)
        XCTAssertEqual(lfu.get(key: "a"), self.testData)
    }
    func test_evict() throws {
        let lfu = LFU(max_size: 5)
        lfu.set(key: "a", value: self.testData)
        XCTAssertEqual(lfu.evict()?.key, "a")
    }
    func test_add_over_max_size_evicts() throws {
        let lfu = LFU(max_size: 1)
        lfu.set(key: "b", value: self.testData)
        lfu.get(key: "b")
        lfu.get(key: "b")
        lfu.set(key: "a", value: self.testData)
        lfu.get(key: "a")
        lfu.get(key: "a")
        lfu.set(key: "c", value: self.testData)
        XCTAssertEqual(lfu.items.count, 1)
        XCTAssertTrue(lfu.history.contains { $0 == "a"})
        XCTAssertTrue(lfu.history.contains { $0 == "b"})
    }
}
