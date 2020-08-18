//
//  PSColumnProtocol.swift
//  PSColumn
//
//  Created by shenwenxin on 2020/8/18.
//  Copyright © 2020 swx. All rights reserved.
//

import Foundation
import UIKit

protocol PSColumnItem {
    func getName()
    func getState() -> State
    func updateState(_ state: State)
}

protocol PSColumnItemView {
    func loadData(_ data: Any)
    func updateState(_ state: State)
}
