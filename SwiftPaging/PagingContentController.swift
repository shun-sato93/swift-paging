//
//  PagingController.swift
//  TerraTalk
//
//  Created by 佐藤駿 on 7/19/16.
//  Copyright © 2016 Joyz Inc. All rights reserved.
//

import UIKit

public class PagingContentController: UIViewController {
    
    internal var onScrolled: (() -> Void)?
    internal var onScrollAnimationEnd: (() -> Void)?
    internal var onInfiniteScrollSwapped: ((indexOrder: [Int], offsetXRatio: CGFloat) -> Void)?
    
    internal let scrollView: UIScrollView = {
        $0.pagingEnabled = true
        $0.showsHorizontalScrollIndicator = false
        $0.showsVerticalScrollIndicator = false
        $0.scrollsToTop = false
        $0.bounces = false
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIScrollView(frame: .zero))
    
    private let controllers: [UIViewController]
    private let defaultPage: Int
    private let infiniteScroll: Bool
    private var scrollSubviews: [UIView] = [UIView]()
    
    init(controllers: [UIViewController], defaultPage: Int = 0, infiniteScroll: Bool = false) {
        self.controllers = controllers
        self.defaultPage = defaultPage
        self.infiniteScroll = infiniteScroll
        super.init(nibName: nil, bundle: nil)
        
        setupView()
        setupScrollView()
        layoutScrollView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.pagingEnabled = true
        
        setupSubviews()
        
        gotoPage(defaultPage, animated: false)
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if infiniteScroll == true {
            onScrolled?()
            relayoutScrollViewForInfiniteScrolling()
            onInfiniteScrollSwapped?(indexOrder: getCurrentIndexOrder(), offsetXRatio: getOffsetXRatio())
        }
    }
    
    // 指定したページに移動
    internal func gotoPage(pageIndex: Int, animated: Bool = true) {
        guard 0 <= pageIndex && pageIndex < scrollView.subviews.count else { return }
        let destinationSubview = scrollView.subviews[pageIndex]
        scrollView.setContentOffset(CGPoint(x: destinationSubview.frame.origin.x, y: 0), animated: animated)
    }
    
    internal func getOffsetXRatio() -> CGFloat {
        return scrollView.contentOffset.x / scrollView.contentSize.width
    }
    
    
    private func setupTestSubviews() {
        let colors:[UIColor] = [UIColor.redColor(), UIColor.blueColor(), UIColor.greenColor(), UIColor.yellowColor()]
        for index in 0..<colors.count {
            var frame: CGRect = CGRectMake(0, 0, 0, 0)
            frame.origin.x = scrollView.frame.size.width * CGFloat(index)
            frame.size = scrollView.frame.size
            
            let subView = UIView(frame: frame)
            subView.backgroundColor = colors[index]
            scrollView.addSubview(subView)
        }
        scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * CGFloat(colors.count), scrollView.frame.size.height)
    }
    
    private func setupSubviews() {
        for (index, controller) in controllers.enumerate() {
            var frame: CGRect = CGRectMake(0, 0, 0, 0)
            frame.origin.x = scrollView.frame.size.width * CGFloat(index)
            frame.size = scrollView.frame.size
            scrollView.pagingEnabled = true
            
            controller.view.frame = frame
            scrollView.addSubview(controller.view)
            self.addChildViewController(controller)
            scrollSubviews.append(controller.view)
        }
        scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * CGFloat(controllers.count), scrollView.frame.size.height)
    }
    
    private func setupView() {
        view.backgroundColor = UIColor.yellowColor()
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupScrollView() {
        scrollView.backgroundColor = UIColor.purpleColor()
        scrollView.scrollEnabled = true
        scrollView.delegate = self
        view.addSubview(scrollView)
    }
    
    private func layoutScrollView() {
        let viewsDictionary = ["scrollView": scrollView]
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[scrollView]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[scrollView]|", options: [], metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
    }
    
    private func relayoutScrollViewForInfiniteScrolling() {
        guard scrollSubviews.count >= 3 else { return }
        
        if scrollView.contentOffset.x < scrollView.frame.width {
            scrollSubviews.last!.frame.origin.x = scrollSubviews.first!.frame.origin.x
            for (index, subview) in scrollSubviews.enumerate() {
                if subview != scrollSubviews.last {
                    subview.frame.origin.x = (CGFloat(index) + 1.0) * scrollView.frame.width
                }
            }
            scrollView.contentOffset.x += scrollView.frame.width
            scrollSubviews.insert(scrollSubviews.removeLast(), atIndex: 0)
        } else if scrollView.contentOffset.x > scrollView.contentSize.width - scrollView.frame.width * 2 {
            scrollSubviews.first!.frame.origin.x = scrollSubviews.last!.frame.origin.x
            for (index, subview) in scrollSubviews.enumerate() {
                if subview != scrollSubviews.first {
                    subview.frame.origin.x = (CGFloat(index) - 1.0) * scrollView.frame.width
                }
            }
            scrollView.contentOffset.x -= scrollView.frame.width
            scrollSubviews.append(scrollSubviews.removeFirst())
        }
    }
    
    private func getCurrentIndexOrder() -> [Int] {
        var indexOrder = [Int]()
        
        guard scrollView.subviews.count == scrollSubviews.count else { return indexOrder }
        
        for (i, subview) in scrollView.subviews.enumerate() {
            if scrollSubviews[0] == subview {
                var index = i
                for _ in 0..<scrollSubviews.count {
                    indexOrder.append(index)
                    index += 1
                    if index >= scrollSubviews.count {
                        index = 0
                    }
                }
                break
            }
        }
        //print("indexOrder=\(indexOrder), currentRatio=\(scrollView.contentOffset.x / scrollView.contentSize.width)")
        return indexOrder
    }
}

extension PagingContentController: UIScrollViewDelegate {
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        onScrolled?()
        
        if infiniteScroll == true {
            relayoutScrollViewForInfiniteScrolling()
        }
    }
    
    // called when manually scroll animation end
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        onScrollAnimationEnd?()
        onInfiniteScrollSwapped?(indexOrder: getCurrentIndexOrder(), offsetXRatio: getOffsetXRatio())
    }
    
    // called when programmatically scroll animation end
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        onScrollAnimationEnd?()
        onInfiniteScrollSwapped?(indexOrder: getCurrentIndexOrder(), offsetXRatio: getOffsetXRatio())
    }
}