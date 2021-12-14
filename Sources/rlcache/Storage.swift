//
//  File.swift
//  
//
//  Created by mdomans on 30/10/2021.
//

import Foundation

class Storage {
    private let queue = DispatchQueue(label: "storage_sync_queue", attributes: .concurrent)
    private var data: LFU
    
    var stats: String {
        return self.data.stats
    }
    
    init(max_size: Int) {
        self.data = LFU(max_size: max_size)
    }
    
    func reset() {
        self.data.reset()
    }
    
    func set(key: String, value: Data) {
        self.queue.async {[weak self] in
            self?.data.set(key: key, value: value)
        }
    }
    
    func get(key: String) -> Data?{
        self.queue.sync {
            return self.data.get(key: key)
        }
    }
    

    
    func debug() -> String {
        return "\(self.data)"
    }
}

