//
//  CategoryRow+.swift
//
//  Created by Michael Bonnette on Oct 23, 2018
//  Copyright © 2018 BlueMedl Inc. All rights reserved.
//

import UIKit

class CategoryRow : UITableViewCell {
	@IBOutlet weak var collectionView: UICollectionView!

	let commands = ["  ", "  ","  ", "  ","Drive", "Transit","Walk", "Drive / Walk","Transit / Walk", "Drive / Transit / Walk","  ","  ","  ","  ","  ","  "]
	var curSelectedCell:ContentCell? = nil
	var selectionColor:UIColor = UIColor.yellow
	var nonSelectionColor:UIColor = UIColor.white
	var nonSelectionFont:UIFont? = nil
	var selectionFont:UIFont? = UIFont.boldSystemFont(ofSize: 11.0)
	var calculationFont:UIFont = UIFont.boldSystemFont(ofSize: 25)

	
	override func awakeFromNib() {
		collectionView.register(UINib(nibName: "ContentCell", bundle: nil), forCellWithReuseIdentifier: "ContentCellID")
		super.awakeFromNib()
	}
	

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

		var locSelectedCell:ContentCell? = nil
		if (curSelectedCell == nil) {
			locSelectedCell = collectionView.cellForItem(at: indexPath) as? ContentCell
		}
		else {
			curSelectedCell?.cmdText.textColor = nonSelectionColor
			curSelectedCell?.cmdText.font = nonSelectionFont
			locSelectedCell = collectionView.cellForItem(at: indexPath) as? ContentCell
		}
		if (locSelectedCell?.cmdText.text != "  ") {
			collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
			curSelectedCell = locSelectedCell
			curSelectedCell?.cmdText.textColor = selectionColor
			curSelectedCell?.cmdText.font = selectionFont
			UISelectionFeedbackGenerator().selectionChanged()
		}
	}
}

extension CategoryRow : UICollectionViewDataSource {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return commands.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContentCellID", for: indexPath) as! ContentCell
		cell.cmdText?.text = commands[indexPath.row]

		// Pull out the existing fonts/colors on first use
		if (nonSelectionFont == nil) {
			nonSelectionFont = cell.cmdText.font
			let ptSize = cell.cmdText.font?.pointSize ?? 11.0
			selectionFont = UIFont.boldSystemFont(ofSize: ptSize + 2.0)
			nonSelectionColor = cell.cmdText.textColor ?? UIColor.white
			if (nonSelectionColor == UIColor.white) {
				selectionColor = UIColor.yellow
			}
			else {
				selectionColor = UIColor.blue
			}
		}
		else {
			cell.cmdText.textColor = nonSelectionColor
			cell.cmdText.font = nonSelectionFont
		}
		return cell
    }
	
}

extension CategoryRow : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemsPerRow:CGFloat = 4
        let hardCodedPadding:CGFloat = 6
		let cmdText = commands[indexPath.row]
		var itemWidth:CGFloat = 0.0
		
		if ( cmdText == "  ") {
			itemWidth = (collectionView.bounds.width / itemsPerRow) - hardCodedPadding
		}
		else {
			itemWidth =	commands[indexPath.row].width(withConstrainedHeight: calculationFont.lineHeight, font:calculationFont)
		}
        let itemHeight = collectionView.bounds.height - (2 * hardCodedPadding)
	
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
}
