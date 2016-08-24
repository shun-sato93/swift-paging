//
//  PagingController.swift
//  TerraTalk
//
//  Created by 佐藤駿 on 7/20/16.
//  Copyright © 2016 Joyz Inc. All rights reserved.
//

class PagingController: UIViewController {
    
    private var pagingContentController: PagingContentController? {
        didSet {
            guard let pagingContentController = pagingContentController else { return }
            
            view.addSubview(pagingContentController.view)
            addChildViewController(pagingContentController)
            pagingContentController.didMoveToParentViewController(self)
        }
    }
    
    private var pagingTabController: PagingTabController? {
        didSet {
            guard let pagingTabController = pagingTabController else { return }
            
            view.addSubview(pagingTabController.view)
        }
    }
    
    // for tab scrolling
    private var synchronizeTabAndContent: Bool = true
    
    internal func setup(controllers: [UIViewController], labels: [String], defaultPage: Int = 0, infiniteScroll: Bool = false) {
        guard controllers.count == labels.count else { print("number of controllers and labels are not same"); return }
        
        pagingContentController = PagingContentController(controllers: controllers, defaultPage: defaultPage, infiniteScroll: infiniteScroll)
        pagingContentController!.onScrolled = { [unowned self] in
            self.onPagingContentViewScrolled()
        }
        pagingContentController!.onScrollAnimationEnd = { [unowned self] in
            self.synchronizeTabAndContent = true
        }
        pagingContentController!.onInfiniteScrollSwapped = { [unowned self] indexOrder, offsetXRatio in
            self.pagingTabController!.synchronizeSubviewIndex(indexOrder, ratio: offsetXRatio)
            self.onPagingContentViewScrolled()
        }
        pagingTabController = PagingTabController(labels: labels, infiniteScroll: infiniteScroll)
        pagingTabController!.onSwitchedByTap = { [unowned self] pageIndex in
            self.pagingContentController?.gotoPage(pageIndex)
        }
        pagingTabController!.onSwitchedByScroll = { [unowned self] pageIndex in
            self.synchronizeTabAndContent = false
            self.pagingContentController?.gotoPage(pageIndex)
        }
        
        layoutTab()
        layoutContent()
    }
    
    private func layoutTab() {
        guard let pagingTabController = pagingTabController else { return }
        
        let viewsDictionary = ["pagingTabController": pagingTabController.view]
        
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[pagingTabController]", options: [], metrics: nil, views: viewsDictionary)
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[pagingTabController]|", options: [], metrics: nil, views: viewsDictionary)
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
        
        pagingTabController.view.setNeedsLayout()
        pagingTabController.view.layoutIfNeeded()
    }
    
    // content viewのレイアウトをセット
    private func layoutContent() {
        guard let pagingContentController = pagingContentController else { return }
        
        var viewsDictionary = ["pagingContentController": pagingContentController.view]
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[pagingContentController]|", options: [], metrics: nil, views: viewsDictionary)
        
        let verticalConstraints: [NSLayoutConstraint]
        if let pagingTabController = self.pagingTabController {
            // タブが存在する場合
            viewsDictionary["pagingTabController"] = pagingTabController.view
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[pagingTabController][pagingContentController]|", options: [], metrics: nil, views: viewsDictionary)
        } else {
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[pagingContentController]|", options: [], metrics: nil, views: viewsDictionary)
        }
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
    }
    
    // content viewがスクロールされた際に呼ばれる
    private func onPagingContentViewScrolled() {
        if synchronizeTabAndContent == true {
            pagingTabController?.scrollByRatio(pagingContentController!.getOffsetXRatio())
        }
    }
}