//
//  File.swift
//  
//
//  Created by mdomans on 14/11/2021.
//

import Foundation

struct FrequencyNode {
    var keys: [String] = []
    
    mutating func remove_item_key(key: String) {
        /// removes key for Item from this fnode
        self.keys = self.keys.filter { k in
            k != key
        }
    }
    
    mutating func add_item_key(key: String) {
        self.keys.append(key)
    }
    
}

struct Item {
    var data: Data
    var frequency = 0
    var key: String
    ///
    /// Size of data cache in bytes
    ///
    public func size() -> Int {
        return self.data.count
    }
}

/// Least Frequently Used cache implementation
///
/// * contains minor rework to avoid linked lists shenaingans
/// * stores values in String to Item map
/// * tracks size of Item
/// * exposes history
///
public class LFU {
    public var history: [String] = []
    var items: [String: Item] = [:]
    // this is the frequency node with f=0
    var frequency_nodes: [FrequencyNode] = [FrequencyNode()]
    // for now this counts amount of key/val pairs rather than amount of memory used
    var max_size: Int = 1000
    var hits = 0
    var accesses = 0
    
    public init(max_size: Int) {
        self.history = []
        self.items = [:]
        self.frequency_nodes = [FrequencyNode()]
        self.max_size = max_size
    }
    
    public var stats: String {
        print("hits: \(self.hits) , accesses: \(self.accesses)")
        return "hits: \(self.hits) , accesses: \(self.accesses)"
    }
    
    func reset() {
        self.history = []
        self.items = [:]
        self.frequency_nodes = [FrequencyNode()]
        self.hits = 0
        self.accesses = 0
    }
    
    func evict() -> Item? {
        // select key/Item pair to remove, return Item
        guard let fnode = self.frequency_nodes.first(where:{(node) in
            node.keys.count > 0
        }) else {
            return nil
        }
        guard let keyToEvict = fnode.keys.randomElement() else {
            return nil
        }
        return self.items.removeValue(forKey: keyToEvict)
    }
    
    public func set(key: String, value: Data){
        if let item = self.items[key] {
            // handle key for elem already in cache
            self.frequency_nodes[item.frequency].remove_item_key(key: key)
        }
        while self.items.count >= self.max_size {
            if let evicted_item = self.evict() {
                self.history.append(evicted_item.key)
            } else {
                break
            }

        }
        let item = Item(data: value, key: key)
        self.frequency_nodes[0].keys.append(key)
        self.items[key] = item
    }

    public func get(key: String) -> Data? {
        self.accesses += 1
        if var item = self.items[key] {
            // pop up frequency count for item +1
            self.frequency_nodes[item.frequency].remove_item_key(key: key)
            // COW because frequency was modified
            item.frequency += 1
            if item.frequency == self.frequency_nodes.count {
                self.frequency_nodes.append(FrequencyNode())
            }
            self.frequency_nodes[item.frequency].add_item_key(key: key)
            self.items[key] = item
            self.hits += 1
            return item.data
        }
        return nil
    }
    
}



