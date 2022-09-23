//
//  EditEnvViewCell.swift
//  Glip
//
//  Created by Leon Xiao on 8/23/18.
//  Copyright © 2018 RingCentral. All rights reserved.
//

import RCCommon
import UIKit

class EditEnvViewCell: UITableViewCell {
    private var detailInfoButton: UIButton = {
        let detailInfoButton = UIButton(type: .infoLight)
        detailInfoButton.translatesAutoresizingMaskIntoConstraints = false
        return detailInfoButton
    }()

    var detailClosure: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpView()
        setUpData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpView() {
        backgroundColor = RCColor.get(.neutralB01)
        contentView.backgroundColor = RCColor.get(.neutralB01)
        contentView.addSubview(detailInfoButton)
        NSLayoutConstraint.activate([
            detailInfoButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            detailInfoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
        ])
    }

    private func setUpData() {
        detailInfoButton.addTarget(self, action: #selector(gotoDetailInfoAction(_:)), for: .touchUpInside)
    }

    @objc private func gotoDetailInfoAction(_ sender: UIButton) {
        detailClosure?()
    }
}
