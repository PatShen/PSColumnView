//
//  PSColumnView.swift
//  PSColumn
//
//  Created by shenwenxin on 2020/8/18.
//  Copyright © 2020 swx. All rights reserved.
//

import UIKit
import SnapKit

enum LayoutStyle: Int {
    /// 左对齐
    case left
    /// 居中对齐
    case center
    /// 平均分（铺满）
    case average
}

class PSColumnView: UIView {
    
    var minItemSizeBlock: (() -> CGSize)?
    
    var itemSpacingBlock: (() -> Double)?
    
    var separatorLineColor: UIColor {
        get {
            self.viewBottomLine.backgroundColor ?? .clear
        }
        set {
            self.viewBottomLine.backgroundColor = newValue
        }
    }
    
    var adaptiveWidthBlock: (() -> Bool)?
    
    var paddingBlock: (() -> UIEdgeInsets)?
    
    final func view(withStyle style: LayoutStyle) -> PSColumnView {
        let view = PSColumnView()
        view.style = style
        return view
    }
    
    func register(view: PSColumnItemView.Type, item: PSColumnItem.Type) {
        let viewClass = String(describing: view.self)
        let itemClass = String(describing: item.self)
        self.relationshipDictionary.updateValue(viewClass, forKey: itemClass)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.style = .left
        self.__installConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.style = .left
        self.__installConstraints()
    }

    // MARK: 成员变量
    private (set) var style: LayoutStyle?
    
    private var relationshipDictionary: [String: String] = [:]
    
    weak var dataSource: PSColumnViewDataSource?
    
    weak var delegate: PSColumnViewDelegate?
    
    lazy var cllList: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        layout.scrollDirection = .horizontal
        
        let cll = UICollectionView.init(frame: .zero, collectionViewLayout: layout)
        cll.backgroundColor = .clear
        cll.showsVerticalScrollIndicator = false
        cll.showsHorizontalScrollIndicator = false
        
        return cll
    }()
    
    lazy var viewBottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    private var itemSize = CGSize.zero
}

// MARK: - UI
extension PSColumnView {
    private func __installConstraints() {
        self.addSubview(self.cllList)
        self.addSubview(self.viewBottomLine)
        
        cllList.snp.makeConstraints { $0.edges.equalToSuperview() }
        viewBottomLine.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1.0/UIScreen.main.scale)
        }
    }
}

// MARK: - Business
extension PSColumnView {
    private func __getDataSourceList() -> [PSColumnItem] {
        return self.dataSource?.itemsInColumnView(self) ?? []
    }
    
    // MARK: 对外
    func reloadData(_ completion: (()->Void)?) {
        let array = self.__getDataSourceList()
        let count = array.count
        
        let itemSpacing = self.itemSpacingBlock?() ?? 0.0
        let padding = self.paddingBlock?() ?? UIEdgeInsets.zero
        let minSize = self.minItemSizeBlock?() ?? CGSize.init(width: 40.0, height: 40.0)
        
        if self.style == .average {
            let width: CGFloat = UIScreen.main.bounds.size.width - CGFloat(itemSpacing * Double(count-1)) - padding.left - padding.right
            var itemWidth: CGFloat = 0.0
            if count > 0 {
                itemWidth = width / CGFloat(count)
            }
            if itemWidth < minSize.width {
                itemWidth = minSize.width
            }
            self.itemSize = CGSize.init(width: itemWidth, height: minSize.height)
        } else {
            self.itemSize = CGSize.init(width: 80.0, height: 40.0)
        }
        
        UIView.animate(withDuration: 0.0, animations: {
            self.cllList.reloadData()
        }) { (finished) in
            if self.style != .center { return }
            let layout = self.cllList.collectionViewLayout as! UICollectionViewFlowLayout
            let width = layout.collectionViewContentSize.width
            self.cllList.snp.remakeConstraints { (make) in
                make.centerX.height.equalToSuperview()
                make.width.lessThanOrEqualTo(width)
                make.width.equalTo(width).priority(.high)
            }
            completion?()
        }
    }
    
    func reload(state: State, atIndex index: Int) {
        if index < 0 { return }
        let array = self.__getDataSourceList()
        if index >= array.count { return }
        
        let item = array[index]
        item.updateState(state)
        let indexPath = IndexPath.init(row: index, section: 0)
        let cell = cllList.cellForItem(at: indexPath)
        if cell == nil {
            cllList.reloadItems(at: [indexPath])
        } else if cell is PSColumnItemView {
            let view = cell as! PSColumnItemView
            view.updateState(state)
        }
    }
    
    func reload(contentAt index: Int) {
        if index < 0 { return }
        let array = self.__getDataSourceList()
        if index >= array.count { return }
        
        let indexPath = IndexPath.init(row: index, section: 0)
        UIView.animate(withDuration: 0.0, animations: {
            self.cllList.reloadItems(at: [indexPath])
        }) { (finished) in
            if self.style != .center {
                return
            }
            let layout = self.cllList.collectionViewLayout as! UICollectionViewFlowLayout
            if layout.collectionViewContentSize.width == self.cllList.frame.size.width {
                return
            }
            // 只有居中样式，且 contentSize 的宽不等于当前 collectionview 宽时，刷新页面，重设宽度
            self.reloadData(nil)
        }
    }
}


// MARK: - UICollectionView 代理方法
extension PSColumnView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let array = self.__getDataSourceList()
        return array.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let array = self.__getDataSourceList()
        let item = array[indexPath.row]
        let key = String(describing: type(of: item).self)
        let className = self.relationshipDictionary[key] ?? ""
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: className, for: indexPath)
        if cell is PSColumnItemView {
            let view = cell as! PSColumnItemView
            view.loadData(item)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.columnView(self, didSelect: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.delegate?.columnView(self, didDeselect: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let adaptive = self.adaptiveWidthBlock?() ?? false
        if (self.style == .left || self.style == .center) && adaptive {
            let array = self.__getDataSourceList()
            let item = array[indexPath.row]
            let key = String(describing: type(of: item).self)
            let className = self.relationshipDictionary[key] ?? ""
            if let cls = Bundle.main.classNamed(className) as? UICollectionViewCell.Type {
                let cell = cls.init(coder: NSCoder.init())
                if cell is PSColumnItemView {
                    let view = cell as! PSColumnItemView
                    view.loadData(item)
                }
                cell?.setNeedsLayout()
                cell?.layoutIfNeeded()
                
                let padding = self.paddingBlock?() ?? UIEdgeInsets.zero
                
                let fittingSize = CGSize.init(width: Int.max, height: Int.max)
                var size = cell?.systemLayoutSizeFitting(fittingSize)
                size?.height = self.bounds.size.height - padding.top - padding.bottom
                return size ?? CGSize.zero
            }
            return .zero
        } else {
            return self.itemSize
        }
    }
}
