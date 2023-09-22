//
//  PieceViewProvider.swift
//  ViewKit
//
//  Created by FanPower on 2023/8/31.
//

import SnapKit

class PieceView: UIView {
    var pieceIndex: Int = 0 {
        didSet {
            unknownImageView.loadImage(fetchUnlightImage?(pieceIndex))
        }
    }
    var fetchUnlightImage: ((Int) -> PuzzlePieceImage?)?
    var tapHandler: (Int) -> Void
    var isSelected: Bool = false
    
    lazy var unknownImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    init(tapHandler: @escaping (Int) -> Void) {
        self.tapHandler = tapHandler
        super.init(frame: .zero)
        
        resetUnknownImageView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reset() {
        if isSelected {
            isSelected = false
            subviews.forEach { $0.removeFromSuperview() }
            resetUnknownImageView()
        }
    }
    
    func resetUnknownImageView() {
        addSubview(unknownImageView)
        unknownImageView.isHidden = false
        unknownImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    @objc
    func handleTap(_ gesture: UITapGestureRecognizer) {
        if isSelected { return }
        isSelected = true
        unknownImageView.isHidden = true
        tapHandler(pieceIndex)
    }
}

class PieceViewProvider {
    var views = [PieceView]()
    var usingViews = [PieceView]()
    var tapHandler: ((UIView, Int) -> Void)?
    var fetchUnlightImage: ((Int) -> PuzzlePieceImage?)?
    
    func reusing(_ index: Int) -> PieceView {
        if let view = views.popLast() {
            view.pieceIndex = index
            usingViews.append(view)
            return view
        } else {
            let view = PieceView { [weak self] index in
                self?.selectedPiece(index)
            }
            view.fetchUnlightImage = fetchUnlightImage
            view.pieceIndex = index
            usingViews.append(view)
            return view
        }
    }
    
    func recycle(_ view: PieceView) {
        view.reset()
        views.append(view)
        usingViews.removeAll {
            $0.pieceIndex == view.pieceIndex
        }
        view.removeFromSuperview()
    }
    
    func recycle(_ index: Int) {
        if let view = usingViews.first (where: {
            $0.pieceIndex == index
        }) {
            recycle(view)
        }
    }
    
    func clearUsing() {
        usingViews.forEach {
            recycle($0)
        }
    }
    
    func selectedPiece(_ index: Int) {
        var view: PieceView?
        usingViews.forEach {
            if $0.pieceIndex != index {
                $0.reset()
            } else {
                view = $0
            }
        }
        guard let view = view else { return }
        tapHandler?(view, index)
    }
}
