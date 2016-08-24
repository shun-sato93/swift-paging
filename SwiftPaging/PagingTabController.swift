//
//  PagingTabController.swift
//  TerraTalk
//
//  Created by 佐藤駿 on 7/20/16.
//  Copyright © 2016 Joyz Inc. All rights reserved.
//

import Foundation

class PagingTabController: UIViewController {
    internal let scrollView: CustomedScrollView = {
        $0.pagingEnabled = false
        $0.showsHorizontalScrollIndicator = false
        $0.showsVerticalScrollIndicator = false
        $0.scrollsToTop = false
        $0.bounces = false
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(CustomedScrollView(frame: .zero))
    
    internal var onSwitchedByTap: ((pageIndex: Int) -> Void)?
    internal var onSwitchedByScroll: ((pageIndex: Int) -> Void)?
    
    // layout definitions
    private var kLabelWidth: CGFloat = 100.0
    private let kTabHeight: CGFloat = 37.0
    private let kRoundRectHeight: CGFloat = 17.5
    private let kRoundRectCornerRadius: CGFloat = 8
    private let kLabelMargin: CGFloat = 30
    private let infiniteScroll: Bool
    
    private let labels: [String]
    private var scrollSubviews: [UIView] = [UIView]()
    
    private let normalLabelColor: UIColor = UIColor.lightGrayColor()
    private let focusedLabelColor: UIColor = UIColor.whiteColor()
    
    lazy private var roundRectView: UIView = {
        $0.userInteractionEnabled = true
        return $0
    }(UIView(frame: .zero))
    
    init(labels: [String], infiniteScroll: Bool) {
        self.labels = labels
        self.infiniteScroll = infiniteScroll
        super.init(nibName: nil, bundle: nil)
        
        setupView()
        
        setupRoundRectView()
        layoutRoundRectView()
        
        setupScrollView()
        layoutScrollView()
    }
    
    required internal init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if scrollView.frame.width > kLabelWidth * 3 {
            kLabelWidth = scrollView.frame.width / 3
        }
        
        setupSubviews()
        relayoutScrollView()
    }
    
    // 指定したページに移動
    internal func scrollByRatio(ratioOfContentOffsetX: CGFloat, animated: Bool = false) {
        guard 0 <= ratioOfContentOffsetX && ratioOfContentOffsetX <= 1.0 else { return }
        
        let offsetX = scrollView.contentSize.width * ratioOfContentOffsetX
        
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: animated)
        
        updateScrollView()
    }
    
    internal func onLabelTapped(sender: PagingTabGestureRecognizer){
        onSwitchedByTap?(pageIndex: sender.pageIndex)
    }
    
    private func setupSubviews() {
        for (index, label) in labels.enumerate() {
            var frame: CGRect = CGRectMake(0, 0, 0, 0)
            frame.origin.x = kLabelWidth * CGFloat(index)
            frame.size.height = scrollView.frame.size.height
            frame.size.width = kLabelWidth
            
            let subview = createLabelView(label, frame: frame, pageIndex: index)
            scrollView.addSubview(subview)
            scrollSubviews.append(subview)
        }
        scrollView.contentSize = CGSizeMake(kLabelWidth * CGFloat(labels.count), scrollView.frame.size.height)
    }
    
    private func createLabelView(text: String, frame: CGRect, pageIndex: Int) -> UIView{
        let subview = UIView(frame: frame)
        let labelView = UILabel()
        labelView.text = text
        labelView.textColor = normalLabelColor
        labelView.font = UIFont.boldSystemFontOfSize(12)
        // 横幅のみテキストに合わせる
        labelView.sizeToFit()
        labelView.frame.size.height = frame.size.height
        labelView.textAlignment = .Center
        subview.addSubview(labelView)
        labelView.frame.origin.x = (subview.frame.size.width - labelView.frame.size.width) / 2
        
        // タップのrecognizerを設定
        let tapRecognizer = PagingTabGestureRecognizer(target: self, action: #selector(PagingTabController.onLabelTapped(_:)))
        tapRecognizer.pageIndex = pageIndex
        subview.addGestureRecognizer(tapRecognizer)
        
        return subview
    }
    
    private func setupView() {
        view.backgroundColor = UIColor.clearColor()
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupScrollView() {
        scrollView.backgroundColor = UIColor.clearColor()
        scrollView.scrollEnabled = true
        scrollView.delegate = self
        scrollView.clipsToBounds = false
        view.addSubview(scrollView)
    }
    
    private func layoutScrollView() {
        let viewsDictionary = ["scrollView": scrollView, "view": view]
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[scrollView]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[scrollView]|", options: [], metrics: nil, views: viewsDictionary)
        let heightConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[view(height)]", options: [], metrics: ["height": kTabHeight], views: viewsDictionary)
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints + heightConstraints)
        
        NSLayoutConstraint.deactivateConstraints(scrollView.constraints)
    }
    
    // need to be called after viewDidLayoutSubviews
    private func relayoutScrollView() {
        // set offset
        scrollView.frame.origin.x = -getScrollViewOffset()
        // set scrollView's inset
        let contentInset = (scrollView.frame.size.width - kLabelWidth)
        scrollView.contentInset.right = contentInset
        scrollView.frame.origin.x = -getScrollViewOffset()
    }
    
    private func setupRoundRectView() {
        roundRectView.backgroundColor = kThemeOrangeColor
        roundRectView.layer.cornerRadius = kRoundRectCornerRadius
        roundRectView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roundRectView)
    }
    
    private func layoutRoundRectView() {
        let viewsDictionary = ["roundRectView": roundRectView, "view": view]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
            "V:[view]-(<=1)-[roundRectView]",
            options: NSLayoutFormatOptions.AlignAllCenterX,
            metrics: nil,
            views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
            "H:[view]-(<=1)-[roundRectView]",
            options: NSLayoutFormatOptions.AlignAllCenterY,
            metrics: nil,
            views: viewsDictionary)
        let heightConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[roundRectView(height)]", options: [], metrics: ["height": kRoundRectHeight], views: viewsDictionary)
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints + heightConstraints)
    }
    
    private func getScrollViewOffset() -> CGFloat {
        return kLabelWidth / 2 - view.frame.size.width / 2
    }
    
    private func getCurrentPage() -> Int {
        let realContentOffsetX = scrollView.contentOffset.x// - getScrollViewOffset()
        return Int(round(CDouble(realContentOffsetX / kLabelWidth)))
    }
    
    private func getCurrentOffsetXRatio() -> CGFloat {
        let remainder = scrollView.contentOffset.x - CGFloat(getCurrentPage()) * kLabelWidth
        return remainder / kLabelWidth
    }
    
    private func updateScrollView() {
        updateRoundRectView()
    }
    
    // update roundRectView's width and x coordinate
    private func updateRoundRectView() {
        // TODO: calculate width
        let index = getCurrentPage()
        var ratio = getCurrentOffsetXRatio()
        
        let currentLabel = scrollSubviews[index].subviews[0] as! UILabel
        var width: CGFloat = currentLabel.frame.width
        
        // scrolling is stopped, so reset text color of all labels
        for subview in scrollSubviews {
            if let label = subview.subviews[0] as? UILabel {
                label.textColor = normalLabelColor
            }
        }
        if ratio < 0 {
            let previousLabel = scrollSubviews[index - 1].subviews[0] as! UILabel
            ratio = abs(ratio)
            width = width + (previousLabel.frame.width - width) * ratio
            previousLabel.textColor = UIColor.mix(focusedLabelColor, secondColor: normalLabelColor, ratioOfFirstColor: ratio)
            currentLabel.textColor = UIColor.mix(normalLabelColor, secondColor: focusedLabelColor, ratioOfFirstColor: ratio)
        } else if ratio > 0 {
            let nextLabel = scrollSubviews[index + 1].subviews[0] as! UILabel
            width = width + (nextLabel.frame.width - width) * ratio
            nextLabel.textColor = UIColor.mix(focusedLabelColor, secondColor: normalLabelColor, ratioOfFirstColor: ratio)
            currentLabel.textColor = UIColor.mix(normalLabelColor, secondColor: focusedLabelColor, ratioOfFirstColor: ratio)
        } else {
            currentLabel.textColor = focusedLabelColor
        }
        // for horizontal padding
        width += kLabelMargin
        
        // calculate x coordinate
        let xCoordinate = (view.frame.width - width) / 2
        
        roundRectView.frame.size.width = width
        roundRectView.frame.origin.x = xCoordinate
    }
    
    
    private func relayoutScrollViewForInfiniteScrolling() {
        guard scrollSubviews.count >= 3 else { return }
        
        if scrollView.contentOffset.x < kLabelWidth {
            scrollSubviews.last!.frame.origin.x = scrollSubviews.first!.frame.origin.x
            for (index, subview) in scrollSubviews.enumerate() {
                if subview != scrollSubviews.last {
                    subview.frame.origin.x = (CGFloat(index) + 1.0) * kLabelWidth
                }
            }
            scrollView.contentOffset.x += kLabelWidth
            scrollSubviews.insert(scrollSubviews.removeLast(), atIndex: 0)
        } else if scrollView.contentOffset.x > scrollView.contentSize.width - kLabelWidth * 2 {
            scrollSubviews.first!.frame.origin.x = scrollSubviews.last!.frame.origin.x
            for (index, subview) in scrollSubviews.enumerate() {
                if subview != scrollSubviews.first {
                    subview.frame.origin.x = (CGFloat(index) - 1.0) * kLabelWidth
                }
            }
            scrollView.contentOffset.x -= kLabelWidth
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
        return indexOrder
    }
    
    internal func synchronizeSubviewIndex(indexOrder: [Int], ratio: CGFloat) {
        guard indexOrder.count == scrollSubviews.count else { return }
        
        scrollSubviews.removeAll()
        for (i, index) in indexOrder.enumerate() {
            scrollSubviews.append(scrollView.subviews[index])
            scrollSubviews.last!.frame.origin.x = CGFloat(i) * kLabelWidth
        }
        //print("tabCurrentIndexOrder=\(getCurrentIndexOrder()) offsetXRatio=\(scrollView.contentOffset.x / scrollView.contentSize.width)")
        
        //scrollByRatio(ratio)
        updateScrollView()
    }
}

extension PagingTabController: UIScrollViewDelegate {
    internal func scrollViewDidScroll(scrollView: UIScrollView) {
        if infiniteScroll == true {
            relayoutScrollViewForInfiniteScrolling()
        }
        updateScrollView()
    }
    
    internal func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let currentSubview = scrollSubviews[getCurrentPage()]
        scrollByRatio(CGFloat(getCurrentPage()) / CGFloat(scrollView.subviews.count), animated: true)
        for (index, subview) in scrollView.subviews.enumerate() {
            if subview == currentSubview {
                onSwitchedByScroll?(pageIndex: index)
                return
            }
        }
    }
    
    // quoted from http://stackoverflow.com/questions/6813270/uiscrollview-custom-paging-size
    internal func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let targetX = scrollView.contentOffset.x + velocity.x * 60.0
        var targetIndex:Int
        if velocity.x > 0 {
            targetIndex = Int(ceil(targetX / kLabelWidth))
        } else {
            targetIndex = Int(floor(targetX / kLabelWidth))
        }
        //print("scrollViewWillEndDragging targetIndex=\(targetIndex), currentPage= indexOrder=\(getCurrentIndexOrder())")
        targetIndex = max(min(targetIndex, labels.count-1), 0)
        targetContentOffset.memory.x = CGFloat(targetIndex) * kLabelWidth
    }
}

// to expand the touch responding area
class CustomedScrollView: UIScrollView {
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        return true
    }
}

internal class PagingTabGestureRecognizer: UITapGestureRecognizer {
    internal var pageIndex: Int = 0
}

extension UIColor {
    var coreImageColor: CoreImage.CIColor? {
        return CoreImage.CIColor(color: self)  // The resulting Core Image color, or nil
    }
    
    // return the mixture color of first color and second color
    class func mix(firstColor: UIColor, secondColor: UIColor, ratioOfFirstColor: CGFloat) -> UIColor {
        guard let firstRGB = firstColor.coreImageColor else { return UIColor.whiteColor() }
        guard let secondRGB = secondColor.coreImageColor else { return UIColor.whiteColor() }
        
        let newRed = firstRGB.red * ratioOfFirstColor + secondRGB.red * (1.0 - ratioOfFirstColor)
        let newGreen = firstRGB.green * ratioOfFirstColor + secondRGB.green * (1.0 - ratioOfFirstColor)
        let newBlue = firstRGB.blue * ratioOfFirstColor + secondRGB.blue * (1.0 - ratioOfFirstColor)
        
        return UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }
}