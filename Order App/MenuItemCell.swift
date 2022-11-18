//
//  MenuItemCell.swift
//  Order App
//
//  Created by Anush Yerzinkyan on 18.11.22.
//

import Foundation
import UIKit

class MenuItemCell: UITableViewCell {
    // swiftlint:disable:next redundant_optional_initialization
    var itemName: String? = nil {
            didSet {
                if oldValue != itemName {
                    setNeedsUpdateConfiguration()
                }
            }
        }
    // swiftlint:disable:next redundant_optional_initialization
    var price: Double? = nil {
            didSet {
                if oldValue != price {
                    setNeedsUpdateConfiguration()
                }
            }
        }
    // swiftlint:disable:next redundant_optional_initialization
    var image: UIImage? = nil {
            didSet {
                if oldValue != image {
                    setNeedsUpdateConfiguration()
                }
            }
        }

    override func updateConfiguration(using state:
       UICellConfigurationState) {
        var content = defaultContentConfiguration().updated(for: state)
        content.text = itemName
        content.secondaryText = price?.formatted(.currency(code: "usd"))
        content.prefersSideBySideTextAndSecondaryText = true

        if let image = image {
            content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
            content.image = image
        } else {
            content.imageProperties.reservedLayoutSize = CGSize(width: 50, height: 50)
            content.image = UIImage(systemName: "photo.on.rectangle")
        }
        self.contentConfiguration = content
    }
}
