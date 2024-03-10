//
//  ViewControllerCell.swift
//  CodingSession
//
//  Created by Yury Krainik on 08/03/2024.
//

import UIKit

final class ViewControllerCell: UICollectionViewCell {

    private(set) lazy var thumbImageView: UIImageView = .init(frame: .zero)
    private(set) lazy var durationLabel: UILabel = .init(frame: .zero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(thumbImageView)
        thumbImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        
        contentView.addSubview(durationLabel)
        durationLabel.snp.makeConstraints {
            $0.leading.equalTo(8)
            $0.bottom.equalTo(-8)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
