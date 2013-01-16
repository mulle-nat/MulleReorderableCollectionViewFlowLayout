//
// LXReorderableCollectionViewFlowLayout.h
//
// Created by Stan Chang Khin Boon on 1/10/12.
// Copyright (c) 2012 d--buzz. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LXReorderableCollectionViewFlowLayout : UICollectionViewFlowLayout < UIGestureRecognizerDelegate>
{
   NSTimer        *scrollingTimer_;
   NSIndexPath    *selectedItemIndexPath_;

   UIEdgeInsets   triggerScrollingEdgeInsets_;
   CGFloat        scrollingSpeed_;
   CGPoint        currentViewCenter_;
   CGPoint        panTranslationInCollectionView_;
   
   // non-retained

   UILongPressGestureRecognizer   *longPressGestureRecognizer_;
   UIPanGestureRecognizer         *panGestureRecognizer_;
   
   UIView         *currentView_;
   
   BOOL           alwaysScroll_;
}


- (void) setUpGestureRecognizersOnCollectionView;

@end



@protocol LXReorderableCollectionViewDelegateFlowLayout<UICollectionViewDelegateFlowLayout>

- (void) collectionView:(UICollectionView *) theCollectionView
                 layout:(UICollectionViewLayout *) theLayout
        itemAtIndexPath:(NSIndexPath *) theFromIndexPath
    willMoveToIndexPath:(NSIndexPath *) theToIndexPath;

@optional

- (BOOL) collectionView:(UICollectionView *) theCollectionView
                 layout:(UICollectionViewLayout *) theLayout
        itemAtIndexPath:(NSIndexPath *) theFromIndexPath
  shouldMoveToIndexPath:(NSIndexPath *) theToIndexPath;

- (BOOL) collectionView:(UICollectionView *) theCollectionView
                 layout:(UICollectionViewLayout *) theLayout
   shouldBeginReorderingAtIndexPath:(NSIndexPath *) theIndexPath;

- (void) collectionView:(UICollectionView *) theCollectionView
                 layout:(UICollectionViewLayout *) theLayout
   willBeginReorderingAtIndexPath:(NSIndexPath *) theIndexPath;

- (void) collectionView:(UICollectionView *) theCollectionView
                 layout:(UICollectionViewLayout *) theLayout
   didBeginReorderingAtIndexPath:(NSIndexPath *) theIndexPath;

- (void) collectionView:(UICollectionView *) theCollectionView
                 layout:(UICollectionViewLayout *) theLayout
   willEndReorderingAtIndexPath:(NSIndexPath *) theIndexPath;

- (void) collectionView:(UICollectionView *) theCollectionView
                 layout:(UICollectionViewLayout *) theLayout
   didEndReorderingAtIndexPath:(NSIndexPath *) theIndexPath;

@end

