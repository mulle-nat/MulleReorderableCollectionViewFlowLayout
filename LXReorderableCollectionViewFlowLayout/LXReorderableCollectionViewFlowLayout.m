//
// LXReorderableCollectionViewFlowLayout.m
//
// Created by Stan Chang Khin Boon on 1/10/12.
// Copyright (c) 2012 d--buzz. All rights reserved.
//

#import "LXReorderableCollectionViewFlowLayout.h"
#import <QuartzCore/QuartzCore.h>

#define LX_FRAMES_PER_SECOND 60.0

#ifndef CGGEOMETRY_LXSUPPORT_H_
CG_INLINE CGPoint LXS_CGPointAdd(CGPoint thePoint1, CGPoint thePoint2)
{
   return(CGPointMake(thePoint1.x + thePoint2.x, thePoint1.y + thePoint2.y));
}


#endif

typedef NS_ENUM (NSInteger, LXDirection) {
   LXUp = 1,
   LXDown,
   LXLeft,
   LXRight
};

static NSString *LXScrollingDirectionKey = @"LXScrollingDirection";



@interface LXReorderableCollectionViewFlowLayout ()

- (void) applyLayoutAttributes:(UICollectionViewLayoutAttributes *) attributes;

@end


@interface UICollectionViewLayoutAttributes ( LXReorderableCollectionViewFlowLayout)

- (void) applyToLayoutIfNeeded:(LXReorderableCollectionViewFlowLayout *) layout;

@end

@implementation UICollectionViewLayoutAttributes ( LXReorderableCollectionViewFlowLayout)

- (void) applyToLayoutIfNeeded:(LXReorderableCollectionViewFlowLayout *) layout
{
   if( [self representedElementCategory] == UICollectionElementCategoryCell)
        [layout applyLayoutAttributes:self];
}
        
@end

        
@implementation LXReorderableCollectionViewFlowLayout

- (void) setUpGestureRecognizersOnCollectionView
{
   UILongPressGestureRecognizer   *longer;
   UIPanGestureRecognizer         *panner;
   
   longer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                          action:@selector( handleLongPressGesture:)];

   // Links the default long press gesture recognizer to the custom long press gesture recognizer we are creating now
   // by enforcing failure dependency so that they doesn't clash.
   for( UIGestureRecognizer *recognizer in self.collectionView.gestureRecognizers)
   {
      if( [recognizer isKindOfClass:[UILongPressGestureRecognizer class]])
         [recognizer requireGestureRecognizerToFail:longer];
   }

   longer.delegate = self;
   [self.collectionView addGestureRecognizer:longer];
   self.longPressGestureRecognizer = longer;

   panner =  [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                     action:@selector( handlePanGesture: )];
   panner.delegate = self;
   [self.collectionView addGestureRecognizer:panner];
   self.panGestureRecognizer = panner;

   self.triggerScrollingEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
   self.scrollingSpeed             = 300.0f;

   [self invalidateAutoScroll];

   self.alwaysScroll   = YES;
}


- (void) awakeFromNib
{
   [self setUpGestureRecognizersOnCollectionView];
}


#pragma mark - Custom methods

- (void) applyLayoutAttributes:(UICollectionViewLayoutAttributes *) theLayoutAttributes
{
   if( [theLayoutAttributes.indexPath isEqual:self.selectedItemIndexPath])
      theLayoutAttributes.hidden = YES;
}


- (void) invalidateLayoutIfNecessary
{
   NSIndexPath   *theIndexPathOfSelectedItem = [self.collectionView indexPathForItemAtPoint:self.currentView.center];

   if((! [theIndexPathOfSelectedItem isEqual:self.selectedItemIndexPath]) && (theIndexPathOfSelectedItem))
   {
      NSIndexPath   *thePreviousSelectedIndexPath = self.selectedItemIndexPath;
      self.selectedItemIndexPath = theIndexPathOfSelectedItem;

      id<LXReorderableCollectionViewDelegateFlowLayout>   theDelegate =
         (id<LXReorderableCollectionViewDelegateFlowLayout> )self.collectionView.delegate;

      if( [theDelegate conformsToProtocol:@protocol( LXReorderableCollectionViewDelegateFlowLayout )])
      {
         // Check with the delegate to see if this move is even allowed.
         if( [theDelegate respondsToSelector:@selector( collectionView:layout:itemAtIndexPath:shouldMoveToIndexPath: )])
         {
            BOOL   shouldMove = [theDelegate collectionView:self.collectionView
                                                     layout:self
                                            itemAtIndexPath:thePreviousSelectedIndexPath
                                      shouldMoveToIndexPath:theIndexPathOfSelectedItem];

            if( ! shouldMove)
               return;
         }

         // Proceed with the move
         [theDelegate collectionView:self.collectionView
                              layout:self
                     itemAtIndexPath:thePreviousSelectedIndexPath
                 willMoveToIndexPath:theIndexPathOfSelectedItem];
      }

      [self.collectionView performBatchUpdates:^{
          // [self.collectionView moveItemAtIndexPath:thePreviousSelectedIndexPath toIndexPath:theIndexPathOfSelectedItem];
          [self.collectionView deleteItemsAtIndexPaths:@[thePreviousSelectedIndexPath]];
          [self.collectionView insertItemsAtIndexPaths:@[theIndexPathOfSelectedItem]];
       } completion:^(BOOL finished) {
       }];
   }
}


#pragma mark - Target/Action methods

- (void) handleScroll:(NSTimer *) theTimer
{
   LXDirection   theScrollingDirection =
      (LXDirection) [theTimer.userInfo[ LXScrollingDirectionKey] integerValue];

   switch( theScrollingDirection)
   {
   case LXUp:
   {
      CGFloat   theDistance      = -(self.scrollingSpeed / LX_FRAMES_PER_SECOND);
      CGPoint   theContentOffset = self.collectionView.contentOffset;
      CGFloat   theMinY          = 0.0f;

      if((theContentOffset.y + theDistance) <= theMinY)
         theDistance = -theContentOffset.y;

      self.collectionView.contentOffset = LXS_CGPointAdd(theContentOffset, CGPointMake(0.0f, theDistance));
      self.currentViewCenter            = LXS_CGPointAdd(self.currentViewCenter, CGPointMake(0.0f, theDistance));
      self.currentView.center           = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
   } break;

   case LXDown:
   {
      CGFloat   theDistance      = (self.scrollingSpeed / LX_FRAMES_PER_SECOND);
      CGPoint   theContentOffset = self.collectionView.contentOffset;
      CGFloat   theMaxY          =
         MAX(self.collectionView.contentSize.height, CGRectGetHeight(self.collectionView.bounds)) - CGRectGetHeight(
            self.collectionView.bounds);

      if((theContentOffset.y + theDistance) >= theMaxY)
         theDistance = theMaxY - theContentOffset.y;

      self.collectionView.contentOffset = LXS_CGPointAdd(theContentOffset, CGPointMake(0.0f, theDistance));
      self.currentViewCenter            = LXS_CGPointAdd(self.currentViewCenter, CGPointMake(0.0f, theDistance));
      self.currentView.center           = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
   } break;

   case LXLeft:
   {
      CGFloat   theDistance      = -(self.scrollingSpeed / LX_FRAMES_PER_SECOND);
      CGPoint   theContentOffset = self.collectionView.contentOffset;
      CGFloat   theMinX          = 0.0f;

      if((theContentOffset.x + theDistance) <= theMinX)
         theDistance = -theContentOffset.x;

      self.collectionView.contentOffset = LXS_CGPointAdd(theContentOffset, CGPointMake(theDistance, 0.0f));
      self.currentViewCenter            = LXS_CGPointAdd(self.currentViewCenter, CGPointMake(theDistance, 0.0f));
      self.currentView.center           = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
   } break;

   case LXRight:
   {
      CGFloat   theDistance      = (self.scrollingSpeed / LX_FRAMES_PER_SECOND);
      CGPoint   theContentOffset = self.collectionView.contentOffset;
      CGFloat   theMaxX          =
         MAX(self.collectionView.contentSize.width, CGRectGetWidth(self.collectionView.bounds)) - CGRectGetWidth(
            self.collectionView.bounds);

      if((theContentOffset.x + theDistance) >= theMaxX)
         theDistance = theMaxX - theContentOffset.x;

      self.collectionView.contentOffset = LXS_CGPointAdd(theContentOffset, CGPointMake(theDistance, 0.0f));
      self.currentViewCenter            = LXS_CGPointAdd(self.currentViewCenter, CGPointMake(theDistance, 0.0f));
      self.currentView.center           = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
   } break;

   default:
      break;
   }
}


- (void) handleLongPressGesture:(UILongPressGestureRecognizer *) theLongPressGestureRecognizer
{
   switch( theLongPressGestureRecognizer.state)
   {
   case UIGestureRecognizerStateBegan:
   {
      CGPoint       theLocationInCollectionView = [theLongPressGestureRecognizer locationInView:self.collectionView];
      NSIndexPath   *theIndexPathOfSelectedItem =
         [self.collectionView indexPathForItemAtPoint:theLocationInCollectionView];

      if( [self.collectionView.delegate conformsToProtocol:@protocol( LXReorderableCollectionViewDelegateFlowLayout )])
      {
         id<LXReorderableCollectionViewDelegateFlowLayout>   theDelegate =
            (id<LXReorderableCollectionViewDelegateFlowLayout> )self.collectionView.delegate;

         if( [theDelegate respondsToSelector:@selector( collectionView:layout:shouldBeginReorderingAtIndexPath: )])
         {
            BOOL   shouldStartReorder =
               [theDelegate collectionView:self.collectionView layout:self shouldBeginReorderingAtIndexPath:
                theIndexPathOfSelectedItem];

            if( ! shouldStartReorder)
               return;
         }

         if( [theDelegate respondsToSelector:@selector( collectionView:layout:willBeginReorderingAtIndexPath: )])
            [theDelegate collectionView:self.collectionView layout:self willBeginReorderingAtIndexPath:
             theIndexPathOfSelectedItem];
      }

      UICollectionViewCell   *theCollectionViewCell =
         [self.collectionView cellForItemAtIndexPath:theIndexPathOfSelectedItem];

      theCollectionViewCell.highlighted = YES;
      UIGraphicsBeginImageContextWithOptions(theCollectionViewCell.bounds.size, theCollectionViewCell.opaque, 0.0f);
      [theCollectionViewCell.layer renderInContext:UIGraphicsGetCurrentContext()];
      UIImage   *theHighlightedImage = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();

      theCollectionViewCell.highlighted = NO;
      UIGraphicsBeginImageContextWithOptions(theCollectionViewCell.bounds.size, theCollectionViewCell.opaque, 0.0f);
      [theCollectionViewCell.layer renderInContext:UIGraphicsGetCurrentContext()];
      UIImage   *theImage = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();

      UIImageView   *theImageView = [[UIImageView alloc] initWithImage:theImage];
      theImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;    // Not using constraints, lets auto resizing mask be translated automatically...

      UIImageView   *theHighlightedImageView = [[UIImageView alloc] initWithImage:theHighlightedImage];
      theHighlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;    // Not using constraints, lets auto resizing mask be translated automatically...

      UIView   *theView =
         [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(theCollectionViewCell.frame),
                                                  CGRectGetMinY(theCollectionViewCell.frame),
                                                  CGRectGetWidth(theImageView.frame),
                                                  CGRectGetHeight(theImageView.frame))];

      [theView addSubview:theImageView];
      [theView addSubview:theHighlightedImageView];

      [self.collectionView addSubview:theView];

      self.selectedItemIndexPath = theIndexPathOfSelectedItem;
      self.currentView           = theView;
      self.currentViewCenter     = theView.center;

      theImageView.alpha            = 0.0f;
      theHighlightedImageView.alpha = 1.0f;

      [UIView
          animateWithDuration:0.3
                   animations:^{
          theView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
          theImageView.alpha = 1.0f;
          theHighlightedImageView.alpha = 0.0f;
       }


                   completion:^(BOOL finished) {
          [theHighlightedImageView removeFromSuperview];

          if( [self.collectionView.delegate conformsToProtocol:@protocol( LXReorderableCollectionViewDelegateFlowLayout )
              ])
          {
             id<LXReorderableCollectionViewDelegateFlowLayout> theDelegate =
                (id<LXReorderableCollectionViewDelegateFlowLayout> )self.collectionView.delegate;

             if( [theDelegate respondsToSelector:@selector( collectionView:layout:didBeginReorderingAtIndexPath: )])
                [theDelegate collectionView:self.collectionView layout:self didBeginReorderingAtIndexPath:
                 theIndexPathOfSelectedItem];
          }
       }];

      [self invalidateLayout];
   } break;

   case UIGestureRecognizerStateEnded:
   {
      NSIndexPath   *theIndexPathOfSelectedItem = self.selectedItemIndexPath;

      if( [self.collectionView.delegate conformsToProtocol:@protocol( LXReorderableCollectionViewDelegateFlowLayout )])
      {
         id<LXReorderableCollectionViewDelegateFlowLayout>   theDelegate =
            (id<LXReorderableCollectionViewDelegateFlowLayout> )self.collectionView.delegate;

         if( [theDelegate respondsToSelector:@selector( collectionView:layout:willEndReorderingAtIndexPath: )])
            [theDelegate collectionView:self.collectionView layout:self willEndReorderingAtIndexPath:
             theIndexPathOfSelectedItem];
      }

      self.selectedItemIndexPath = nil;
      self.currentViewCenter     = CGPointZero;

      if( theIndexPathOfSelectedItem)
      {
         UICollectionViewLayoutAttributes   *theLayoutAttributes =
            [self layoutAttributesForItemAtIndexPath:theIndexPathOfSelectedItem];

         __weak LXReorderableCollectionViewFlowLayout   *theWeakSelf = self;
         [UIView
             animateWithDuration:0.3f
                      animations:^{
             __strong LXReorderableCollectionViewFlowLayout *theStrongSelf = theWeakSelf;

             theStrongSelf.currentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
             theStrongSelf.currentView.center = theLayoutAttributes.center;
          }


                      completion:^(BOOL finished) {
             __strong LXReorderableCollectionViewFlowLayout *theStrongSelf = theWeakSelf;

             [theStrongSelf.currentView removeFromSuperview];
             [theStrongSelf invalidateLayout];

             if( [self.collectionView.delegate conformsToProtocol:@protocol(
                     LXReorderableCollectionViewDelegateFlowLayout )])
             {
                id<LXReorderableCollectionViewDelegateFlowLayout> theDelegate =
                   (id<LXReorderableCollectionViewDelegateFlowLayout> )self.collectionView.delegate;

                if( [theDelegate respondsToSelector:@selector( collectionView:layout:didEndReorderingAtIndexPath: )])
                   [theDelegate collectionView:self.collectionView layout:self didEndReorderingAtIndexPath:
                    theIndexPathOfSelectedItem];
             }
          }];
      }
   } break;

   default:
      break;
   }
}


- (void) invalidateAutoScroll
{
   [[self scrollingTimer] invalidate];
   [self setScrollingTimer:nil];
}


- (void) setupAutoScrollInDirection:(NSInteger) dir
{
   BOOL       flag;
   NSTimer    *timer;
   
   flag = YES;
   
   timer = [self scrollingTimer];
   
   if( timer)
   {
      if( [timer isValid])
      {
         flag = [[[timer userInfo] objectForKey:LXScrollingDirectionKey] integerValue] != dir;
      }
   }
   
   if( flag)
   {
      [self invalidateAutoScroll];
      
      timer = [NSTimer scheduledTimerWithTimeInterval:1.0 / LX_FRAMES_PER_SECOND
                                               target:self
                                             selector:@selector( handleScroll:)
                                             userInfo:@{ LXScrollingDirectionKey : @( dir ) }
                                              repeats:YES];
      
      [self setScrollingTimer:timer];
   }
}


- (void) handlePanGesture:(UIPanGestureRecognizer *) recognizer
{
   CGPoint        translation;
   CGPoint        location;
   UIEdgeInsets   insets;
   UICollectionView   *collectionView;
   CGRect          bounds;
   
   switch( [recognizer state])
   {
      case UIGestureRecognizerStateBegan   :
      case UIGestureRecognizerStateChanged :
      {
         translation = [recognizer translationInView:self.collectionView];
         location = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);

         self.panTranslationInCollectionView = translation;
         self.currentView.center = location;
         
         [self invalidateLayoutIfNecessary];
   
         insets         = [self triggerScrollingEdgeInsets];
         collectionView = [self collectionView];
         bounds         = [collectionView bounds];
         
         switch( [self scrollDirection])
         {
            case UICollectionViewScrollDirectionVertical :
               if( location.y < (CGRectGetMinY( bounds) + insets.top))
                  [self setupAutoScrollInDirection:LXUp];
               else
                  if( location.y > (CGRectGetMaxY( bounds) - insets.bottom))
                     [self setupAutoScrollInDirection:LXDown];
                  else
                     [self invalidateAutoScroll];
               
               break;
               
            case UICollectionViewScrollDirectionHorizontal :
               if( location.x < (CGRectGetMinX( bounds) + insets.left))
                  [self setupAutoScrollInDirection:LXLeft];
               else
                  if( location.x > (CGRectGetMaxX( bounds) - insets.right))
                     [self setupAutoScrollInDirection:LXRight];
                  else
                     [self invalidateAutoScroll];
               
               break;
         }
      }
         break;
         
      case UIGestureRecognizerStateEnded:
         [self invalidateAutoScroll];
         break;
   }
}


#pragma mark - UICollectionViewFlowLayoutDelegate methods


- (NSArray *) layoutAttributesForElementsInRect:(CGRect) theRect
{
   NSArray   *array;

   array = [super layoutAttributesForElementsInRect:theRect];
   
   [array makeObjectsPerformSelector:@selector( applyToLayoutIfNeeded:)
                                    withObject:self];
   return( array);
}


- (UICollectionViewLayoutAttributes *) layoutAttributesForItemAtIndexPath:(NSIndexPath *) path
{
   UICollectionViewLayoutAttributes   *attributes;
   
   attributes = [super layoutAttributesForItemAtIndexPath:path];
   [attributes applyToLayoutIfNeeded:self];

   return( attributes);
}


- (CGSize) collectionViewContentSize
{
   CGSize   size;
   CGRect   bounds;
   
   size = [super collectionViewContentSize];
   
   if( ! [self alwaysScroll])
      return( size);
   
   bounds = [[self collectionView] bounds];
   switch( [self scrollDirection])
   {
   case UICollectionViewScrollDirectionVertical :
      if( size.height <= CGRectGetHeight( bounds))
         size.height = CGRectGetHeight(bounds) + 1.0f;
      break;
      
   case UICollectionViewScrollDirectionHorizontal :
      if( size.width <= CGRectGetWidth( bounds))
         size.width = CGRectGetWidth( bounds) + 1.0f;
      break;
   }
   
   return( size);
}


#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer *) recognizer
{
   if( [[self panGestureRecognizer] isEqual:recognizer])
      return( [self selectedItemIndexPath] != nil);

   return( YES);
}


- (BOOL) gestureRecognizer:(UIGestureRecognizer *) recognizer
   shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *) other
{
   UIGestureRecognizer   *panner;
   UIGestureRecognizer   *longer;
   
   panner = [self panGestureRecognizer];
   longer = [self longPressGestureRecognizer];
   
   if( [longer isEqual:recognizer])
      return( [panner isEqual:other]);
   
   if( [panner isEqual:recognizer])
      return( [longer isEqual:other]);
   
   return( NO);
}

@end

