//
//  PuzzlePieceView.swift
//  KeepMoving
//
//  Created by FanPower on 2023/8/21.
//

import UIKit
import Foundation
import Kingfisher

public enum PuzzlePieceError: Error {
    case unsetSize
    case notfoundPiece
}

public class PuzzlePieceView: UIView {
    // 行数
    var hPieceLineCount: Int {
        hPieceLines.count - 1
    }
    // 列数
    var vPieceLineCount: Int {
        vPieceLines.count - 1
    }
    var hump: CGFloat = 20.0
    var hPieceLines = [[Int]]()
    var vPieceLines = [[Int]]()
    var maskLayer = CALayer()
    var lineLayer = CAShapeLayer()
    var lightPieceNumSet = Set<Int>()
    lazy var pieceViewProvider: PieceViewProvider = {
        let pieceViewProvider = PieceViewProvider()
        pieceViewProvider.tapHandler = { [weak self] view, index in
            self?.delegate?.pieceDidClick(pieceView: view, pieceNum: index)
        }
        pieceViewProvider.fetchUnlightImage = { [weak self] index in
            self?.dataSource?.undiscoveredCoverImage(pieceNum: index)
        }
        return pieceViewProvider
    }()
    
    public weak var delegate: PuzzlePieceViewDelegate?
    public weak var dataSource: PuzzlePieceViewDateSource?
        
    lazy var blackMaskView: UIView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.alpha = 0.8
        return blurEffectView
    }()
    
    lazy var bgImageView: UIImageView = {
        let imageView = UIImageView()
        addSubview(imageView)
        return imageView
    }()
    
    lazy var fgImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.mask = maskLayer
        addSubview(imageView)
        return imageView
    }()
    
    public init() {
        super.init(frame: .zero)
        addSubview(bgImageView)
        addSubview(blackMaskView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func safeReload() {
        do {
            try reload()
        } catch {
            print(error)
        }
    }
    
    public func reload() throws {
        guard let dataSource = dataSource else { return }
        /// 处理拼边框
        let matrix = dataSource.matrixValue().matrixValue
        if hPieceLines == matrix.0,
           vPieceLines == matrix.1,
           hump == dataSource.humpWidth() { // 未变化
        } else {
            hPieceLines = matrix.0
            vPieceLines = matrix.1
            /// 拼图边缘凸起宽度
            hump = dataSource.humpWidth()
            resetAllDrawedPieces()
            try drawBaseView()
        }
        
        /// 处理图片
        let imageType = dataSource.puzzlePieceImage()
        bgImageView.loadImage(imageType)
        fgImageView.loadImage(imageType)
        
        /// 处理点亮
        let lights = dataSource.discoveredPiectNums()
        try drawPieces(nums: lights)
        
        /// 处理拼图块状态
        pieceViewProvider.clearUsing()
        for index in 1...(vPieceLineCount * hPieceLineCount) {
            if !lights.contains(index) {
                addTouthablePiece(index)
            }
        }
    }
    
    func addTouthablePiece(_ index: Int) {
        let pieceNum = index - 1
        let row = pieceNum / vPieceLineCount
        let column = pieceNum % vPieceLineCount
        let pieceView = pieceViewProvider.reusing(index)
        pieceView.frame = CGRect(x: pieceW.multiply(column),
                                 y: pieceH.multiply(row),
                                 width: pieceW,
                                 height: pieceH)
        addSubview(pieceView)
    }
    
    func drawBaseView() throws {
        layoutIfNeeded()
        if frame.isEmpty {
            throw PuzzlePieceError.unsetSize
        }
        bgImageView.frame = bounds
        fgImageView.frame = bounds
        blackMaskView.frame = bounds
        drawLine()
    }
    
    func resetAllDrawedPieces() {
        lightPieceNumSet.removeAll()
        maskLayer.sublayers?.removeAll()
    }
}

extension PuzzlePieceView {
    
    var pieceW: CGFloat {
        bounds.width / CGFloat(vPieceLineCount)
    }
    
    var pieceH: CGFloat {
        bounds.height / CGFloat(hPieceLineCount)
    }
    
    func drawPieces(nums: [Int]) throws {
        try nums.forEach {
            do {
                try drawPiece(num: $0)
            } catch {
                throw error
            }
        }
    }
    
    func drawPiece(num: Int) throws {
        if num > hPieceLineCount * vPieceLineCount { // 超出了
            throw PuzzlePieceError.notfoundPiece
        }
        //已经点亮
        if lightPieceNumSet.contains(num) { return }
        pieceViewProvider.recycle(num)
        
        let pieceNum = num - 1
        let row = pieceNum / vPieceLineCount
        let column = pieceNum % vPieceLineCount
        
        let leftTopPoint = CGPoint(x: pieceW.multiply(column), y: pieceH.multiply(row))
        let rightTopPoint = CGPoint(x: pieceW.multiply(column + 1), y: pieceH.multiply(row))
        let rightBottomPoint = CGPoint(x: pieceW.multiply(column + 1), y: pieceH.multiply(row + 1))
        let leftBottomPoint = CGPoint(x: pieceW.multiply(column), y: pieceH.multiply(row + 1))
        let path = UIBezierPath()
        path.move(to: leftTopPoint)
        let topHump = hPieceLines[row][column]
        tieLine(path: path, point: rightTopPoint, humpValue: hPieceLines[row][column], direction: .top)
        let rightHump = vPieceLines[column + 1][row]
        tieLine(path: path, point: rightBottomPoint, humpValue: vPieceLines[column + 1][row], direction: .right)
        let bottomHump = hPieceLines[row + 1][column]
        tieLine(path: path, point: leftBottomPoint, humpValue: hPieceLines[row + 1][column], direction: .bottom)
        let leftHump = vPieceLines[column][row]
        tieLine(path: path, point: leftTopPoint, humpValue: vPieceLines[column][row], direction: .left)
        
        print("""
        -------------
            \(topHump)
        \(leftHump)         \(rightHump)
            \(bottomHump)
        -------------
        """)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.red.cgColor
        maskLayer.addSublayer(shapeLayer)
        fgImageView.layer.mask = maskLayer
        layer.insertSublayer(fgImageView.layer, below: lineLayer)
        lightPieceNumSet.insert(num)
    }
    
    enum LineDirection: Int {
        case top = 0
        case right
        case bottom
        case left
    }
    
    func tieLine(path: UIBezierPath, point: CGPoint, humpValue: Int, direction: LineDirection) {
        if humpValue == 0 {
            path.addLine(to: point)
        } else {
            let startPoint = path.currentPoint
            let endPoint = point

            let insertPoint = CGPoint.insertPointBetween(insert: hump, point1: startPoint, point2: endPoint)
            path.addLine(to: insertPoint)
            let redius = hump * 0.5
            switch direction {
            case .top, .right:
                path.addArc(withCenter: CGPoint.midPointBetween(point1: startPoint, point2: endPoint),
                            radius: redius,
                            startAngle: CGFloat.pi + CGFloat.pi * 0.5 * CGFloat(direction.rawValue),
                            endAngle: CGFloat.pi * 0.5 * CGFloat(direction.rawValue),
                            clockwise: (humpValue > 0 ? true : false))
            case .bottom, .left:
                path.addArc(withCenter: CGPoint.midPointBetween(point1: startPoint, point2: endPoint),
                            radius: redius,
                            startAngle: CGFloat.pi + CGFloat.pi * 0.5 * CGFloat(direction.rawValue),
                            endAngle: CGFloat.pi * 0.5 * CGFloat(direction.rawValue),
                            clockwise: (humpValue < 0 ? true : false))
            }
            path.addLine(to: endPoint)
        }
    }
    
    func drawLine() {
        let griddingPath = UIBezierPath()
        for index in 1..<hPieceLineCount {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: pieceH.multiply(index)))
            for (hIndex, value) in hPieceLines[index].enumerated() {
                tieLine(path: path,
                        point: .init(x: pieceW.multiply(hIndex + 1),
                                     y: pieceH.multiply(index)),
                        humpValue: value,
                        direction: .top)
            }
            griddingPath.append(path)
        }
        
        for index in 1..<vPieceLineCount {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: pieceW.multiply(index), y: 0))
            for (vIndex, value) in vPieceLines[index].enumerated() {
                tieLine(path: path,
                        point: .init(x: pieceW.multiply(index),
                                     y: pieceH.multiply(vIndex + 1)),
                        humpValue: value,
                        direction: .right)
            }
            griddingPath.append(path)
        }

        lineLayer.path = griddingPath.cgPath
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.strokeColor = UIColor(red: 51.0 / 255.0,
                                        green: 51.0 / 255.0,
                                        blue: 51.0 / 255.0,
                                        alpha: 0.5).cgColor
        lineLayer.lineWidth = 0.5
        layer.addSublayer(lineLayer)
    }
    
    func getRowColumn(_ point: CGPoint) -> (row: Int, column: Int) {
        let row = Int(point.y / pieceH)
        let column = Int(point.x / pieceW)
        return (row, column)
    }
    
    func getPieceNum(_ point: CGPoint) -> Int {
        let (row, column) = getRowColumn(point)
        return row * vPieceLineCount + column + 1
    }
    
    func getPieceFrame(_ point: CGPoint) -> CGRect {
        let (row, column) = getRowColumn(point)
        return .init(x: pieceW.multiply(column),
                     y: pieceH.multiply(row),
                     width: pieceW,
                     height: pieceH)
    }
}

extension CGFloat {
    func multiply(_ mulriple: Int) -> CGFloat {
        return self * CGFloat(mulriple)
    }
}

extension CGPoint {
    static func midPointBetween(point1: CGPoint, point2: CGPoint) -> CGPoint {
        return CGPoint(x: (point1.x + point2.x) / 2, y: (point1.y + point2.y) / 2)
    }
    
    static func percentPointBetween(percent: CGFloat, point1: CGPoint, point2: CGPoint) -> CGPoint {
        return CGPoint(x: (point2.x - point1.x) * percent + point1.x,
                       y: (point2.y - point1.y) * percent + point1.y)
    }
    
    static func insertPointBetween(insert: CGFloat, point1: CGPoint, point2: CGPoint) -> CGPoint {
        if point1.x == point2.x {
            return CGPoint(x: point1.x,
                           y: (point2.y + point1.y - insert) * 0.5)
        } else if point1.y == point2.y {
            return CGPoint(x: (point2.x + point1.x - insert) * 0.5,
                           y: point1.y)
        } else {
            fatalError("points mast same x or y")
        }
    }
}
