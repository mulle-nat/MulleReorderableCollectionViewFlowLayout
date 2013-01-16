//
//  PlayingCardCell.h
//  LXRCVFL Example using Storyboard
//
//  Created by Stan Chang Khin Boon on 3/10/12.
//  Copyright (c) 2012 d--buzz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PlayingCard;

@interface PlayingCardCell : UICollectionViewCell

@property (assign, nonatomic) PlayingCard *playingCard;

@property (assign, nonatomic) IBOutlet UIImageView *playingCardImageView;


@end
