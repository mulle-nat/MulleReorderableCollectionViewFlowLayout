//
//  MulleCollectionViewController.h
//  Demo
//
//  Created by Stan Chang Khin Boon on 3/10/12.
//  Copyright (c) 2012 d--buzz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MulleReorderableCollectionViewFlowLayout.h"

@interface MulleCollectionViewController : UICollectionViewController<MulleReorderableCollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSMutableArray *deck;

@end
