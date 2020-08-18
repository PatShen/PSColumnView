//
//  PSColumnViewProtocol.swift
//  PSColumn
//
//  Created by shenwenxin on 2020/8/18.
//  Copyright © 2020 swx. All rights reserved.
//

import Foundation

protocol PSColumnViewDataSource: AnyObject {
    func itemsInColumnView(_ view: PSColumnView) -> [PSColumnItem]
}

protocol PSColumnViewDelegate: AnyObject {
    func columnView(_ view: PSColumnView, didSelect index: Int)
    func columnView(_ view: PSColumnView, didDeselect index: Int)
}

extension PSColumnViewDelegate {
    func columnView(_ view: PSColumnView, didSelect index: Int) {
        
    }
    
    func columnView(_ view: PSColumnView, didDeselect index: Int) {
        
    }
}
