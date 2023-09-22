//
//  ViewController.swift
//  PuzzlePiece
//
//  Created by FanPower on 09/22/2023.
//  Copyright (c) 2023 FanPower. All rights reserved.
//

import PuzzlePiece
import UIKit

class ViewController: UIViewController {

    var pView: PuzzlePieceView!
    var lightList: [Int] = [1, 3]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pView = PuzzlePieceView()
        pView.delegate = self
        pView.dataSource = self
        view.addSubview(pView)
        pView.layer.cornerRadius = 18
        pView.layer.masksToBounds = true
        pView.snp.makeConstraints { make in
            make.top.equalTo(100)
            make.left.equalTo(100)
            make.size.equalTo(CGSize(width: 200, height: 200))
        }
        pView.safeReload()
    }


}

extension ViewController: PuzzlePieceViewDelegate {
    func pieceDidClick(pieceView: UIView, pieceNum: Int) {
        // do something
        lightList.append(pieceNum)
        pView.safeReload()
    }
}

extension ViewController: PuzzlePieceViewDateSource {
    func puzzlePieceImage() -> PuzzlePieceImage {
        return .imageStr("https://bkimg.cdn.bcebos.com/pic/50da81cb39dbb6fd770065eb0824ab18962b37a7")
//        return .image(UIImage(named: "puzzleImage"))
    }
    
    func matrixValue() -> PieceMatrix {
        .grid3x3
    }
    
    func humpWidth() -> CGFloat {
        20
    }
    
    func discoveredPiectNums() -> [Int] {
        lightList
    }
    
    func undiscoveredCoverImage(pieceNum: Int) -> PuzzlePiece.PuzzlePieceImage {
        return .image(UIImage(named: "unknown"))
    }
}
