//
//  PuzzlePieceProtocol.swift
//  ViewKit
//
//  Created by FanPower on 2023/8/31.
//

import UIKit
import Kingfisher

public enum PuzzlePieceImage {
    case image(UIImage?)
    case imageStr(String)
}
 
public enum PieceMatrix {
    case grid2x2
    case grid3x3
    case grid3x4
    case grid4x4
    case gridCustom(hLines: [[Int]], vLines: [[Int]])
    
    public var matrixValue: (row: [[Int]], column: [[Int]]) {
        switch self {
        case .grid2x2:
            return ([[0, 0], [-1, 1], [0, 0]],
                    [[0, 0], [-1, 1], [0, 0]])
        case .grid3x3:
            return ([[0, 0, 0], [-1, 1, -1], [1, -1, 1], [0, 0, 0]],
                    [[0, 0, 0], [1, -1, 1], [-1, 1, -1], [0, 0, 0]])
        case .grid3x4:
            return ([[0, 0, 0], [1, -1, 1], [-1, 1, -1], [1, -1, 1], [0, 0, 0]],
                    [[0, 0, 0, 0], [1, -1, 1, -1], [-1, 1, -1, 1], [0, 0, 0, 0]])
        case .grid4x4:
            return ([[0, 0, 0, 0], [1, -1, 1, -1], [-1, 1, -1, 1], [1, -1, 1, -1], [0, 0, 0, 0]],
                    [[0, 0, 0, 0], [-1, 1, -1, 1], [1, -1, 1, -1], [-1, 1, -1, 1], [0, 0, 0, 0]])
        case let .gridCustom(hLines, vLines):
            return (hLines, vLines)
        }
    }
}

public protocol PuzzlePieceViewDelegate: AnyObject {
    /// 拼图块点击时间
    /// - Parameters:
    ///   - pieceView: 拼图块，可以添加自定义视图
    ///   - pieceNum: 拼图序号，从1开始横向计算
    func pieceDidClick(pieceView: UIView, pieceNum: Int)
}

public protocol PuzzlePieceViewDateSource: AnyObject {
    /// 边框矩阵
    func matrixValue() -> PieceMatrix
    /// 拼图凸起直径
    func humpWidth() -> CGFloat
    /// 已经发现的拼图序号，拼图序号从1开始横向计算
    func discoveredPiectNums() -> [Int]
    /// 拼图完整图片
    func puzzlePieceImage() -> PuzzlePieceImage
    /// 未点亮拼图图标
    func undiscoveredCoverImage(pieceNum: Int) -> PuzzlePieceImage
}

extension UIImageView {
    func loadImage(_ type: PuzzlePieceImage?) {
        switch type {
        case .none:
            return
        case .image(let image):
            self.image = image
        case .imageStr(let imageURLStr):
            kf.setImage(with: URL(string: imageURLStr))
        }
    }
}
