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

// should prefix these messages

@interface UICollectionViewCell (LXReorderableCollectionViewFlowLayout )

- (UIImage *) renderedImage;

@end


@implementation UICollectionViewCell ( LXReorderableCollectionViewFlowLayout )

- (UIImage *) renderedImage
{
   UIImage   *image;
   
   UIGraphicsBeginImageContextWithOptions( [self bounds].size, [self isOpaque], 0.0f);
   [[self layer] renderInContext:UIGraphicsGetCurrentContext()];
   image = UIGraphicsGetImageFromCurrentImageContext();
   UIGraphicsEndImageContext();
   
   return( image);
}

@end

        
@implementation LXReorderableCollectionViewFlowLayout


static LXDirection   autoScrollDirection( NSTimer *timer)
{
   return( [[[timer userInfo] objectForKey:LXScrollingDirectionKey] integerValue]);
}


- (void) invalidateAutoScroll
{
   [scrollingTimer_ invalidate];
   scrollingTimer_ = nil;
}


- (void) setupAutoScrollInDirection:(NSInteger) dir
{
   NSInteger  oldDir;
   
   if( [scrollingTimer_ isValid])
   {
      oldDir = autoScrollDirection( scrollingTimer_);
      if( dir == oldDir)
         return;
   }
   
   [self invalidateAutoScroll];
   
   scrollingTimer_ = [[NSTimer scheduledTimerWithTimeInterval:1.0 / LX_FRAMES_PER_SECOND
                                            target:self
                                          selector:@selector( handleScroll:)
                                          userInfo:@{ LXScrollingDirectionKey : @( dir ) }
                                                      repeats:YES] retain];
}


- (void) setUpGestureRecognizersOnCollectionView
{
   UICollectionView   *collectionView;
   
   collectionView = [self collectionView];
   
   longPressGestureRecognizer_ = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                          action:@selector( handleLongPressGesture:)];

   [longPressGestureRecognizer_ setDelegate:self];
   [collectionView addGestureRecognizer:longPressGestureRecognizer_];

   // Links the default long press gesture recognizer to the custom long press
   // gesture recognizer we are creating now by enforcing failure dependency
   // so that they doesn't clash.
   for( UIGestureRecognizer *recognizer in [collectionView gestureRecognizers])
   {
      if( [recognizer isKindOfClass:[UILongPressGestureRecognizer class]])
         [recognizer requireGestureRecognizerToFail:longPressGestureRecognizer_];
   }
   

   panGestureRecognizer_ = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector( handlePanGesture:)];
   [panGestureRecognizer_ setDelegate:self];
   [collectionView addGestureRecognizer:panGestureRecognizer_];

   triggerScrollingEdgeInsets_ = UIEdgeInsetsMake( 50.0f, 50.0f, 50.0f, 50.0f);
   scrollingSpeed_             = 300.0f;

   [self invalidateAutoScroll];

   alwaysScroll_ = YES;
}


- (void) awakeFromNib
{
   [self setUpGestureRecognizersOnCollectionView];
}


#pragma mark - Custom methods

- (void) applyLayoutAttributes:(UICollectionViewLayoutAttributes *) attributes
{
   if( [[attributes indexPath] isEqual:selectedItemIndexPath_])
      [attributes setHidden:YES];
}


- (void) invalidateLayoutIfNecessary
{
   NSIndexPath        *selectedPath;
   NSIndexPath        *previousPath;
   UICollectionView   *collectionView;
   id<LXReorderableCollectionViewDelegateFlowLayout>   delegate;
   
   collectionView = [self collectionView];
   selectedPath   = [collectionView indexPathForItemAtPoint:[currentView_ center]];
   previousPath   = selectedItemIndexPath_;
   
   if( ! selectedPath || [selectedPath isEqual:previousPath])
      return;
   
   [selectedItemIndexPath_ autorelease];
   selectedItemIndexPath_ = [selectedPath copy];
   
   delegate = (id <LXReorderableCollectionViewDelegateFlowLayout> ) [collectionView delegate];
   if( [delegate conformsToProtocol:@protocol( LXReorderableCollectionViewDelegateFlowLayout)])
   {
      // Check with the delegate to see if this move is even allowed.
      if( [delegate respondsToSelector:@selector( collectionView:layout:itemAtIndexPath:shouldMoveToIndexPath: )])
         if( ! [delegate collectionView:collectionView
                                        layout:self
                               itemAtIndexPath:previousPath
                         shouldMoveToIndexPath:selectedPath])
            return;
      
      // Proceed with the move
      [delegate collectionView:collectionView
                        layout:self
               itemAtIndexPath:previousPath
           willMoveToIndexPath:selectedPath];
   }
   
   [collectionView performBatchUpdates:^{
      // [self.collectionView moveItemAtIndexPath:previousPath toIndexPath:selectedPath];
      [collectionView deleteItemsAtIndexPaths:@[previousPath]];
      [collectionView insertItemsAtIndexPaths:@[selectedPath]];
   } completion:^(BOOL finished) {
   }];
}


#pragma mark - Target/Action methods

- (void) handleScroll:(NSTimer *) timer
{
   UICollectionView   *collectionView;
   LXDirection   dir;
   CGFloat   theDistance;
   CGPoint   theContentOffset;
   CGPoint   translation;
   CGRect    bounds;
   CGSize    contentSize;
   CGFloat   theMinX;
   CGFloat   theMaxX;
   CGFloat   theMinY;
   CGFloat   theMaxY;
   
   dir              = (LXDirection) autoScrollDirection( timer);

   theDistance      = scrollingSpeed_ / LX_FRAMES_PER_SECOND;
   collectionView   = [self collectionView];
   theContentOffset = [collectionView contentOffset];
   bounds           = [collectionView bounds];
   contentSize      = [collectionView contentSize];
   
   switch( dir)
   {
   case LXUp:
      theDistance = -theDistance;
      theMinY     = 0.0f;

      if( (theContentOffset.y + theDistance) <= theMinY)
         theDistance = -theContentOffset.y;

      translation = CGPointMake( 0.0f, theDistance);
      break;

   case LXDown:
      theMaxY = MAX( contentSize.height, CGRectGetHeight( bounds)) - CGRectGetHeight( bounds);

      if( (theContentOffset.y + theDistance) >= theMaxY)
         theDistance = theMaxY - theContentOffset.y;
         
      translation = CGPointMake( 0.0f, theDistance);
      break;

   case LXLeft:
      theDistance = -theDistance;
      theMinX     = 0.0f;

      if( (theContentOffset.x + theDistance) <= theMinX)
         theDistance = -theContentOffset.x;
         
      translation = CGPointMake( theDistance, 0.0f);
      break;

   case LXRight:
      theMaxX = MAX( contentSize.width, CGRectGetWidth( bounds)) - CGRectGetWidth( bounds);

      if((theContentOffset.x + theDistance) >= theMaxX)
         theDistance = theMaxX - theContentOffset.x;
      translation = CGPointMake( theDistance, 0.0f);
      break;

   default:
         abort();
   }
   
   
   currentViewCenter_ = LXS_CGPointAdd( currentViewCenter_, translation);
   [currentView_ setCenter:LXS_CGPointAdd( currentViewCenter_, panTranslationInCollectionView_)];

   [collectionView setContentOffset:LXS_CGPointAdd( theContentOffset, translation)];
}




typedef struct
{
   UIImageView   *theImageView;
   UIImageView   *theHighlightedImageView;
   
   UIView        *theView;
} reorder_views_context;


- (void) constructViews:(reorder_views_context *) ctxt
               withCell:(UICollectionViewCell *) theCollectionViewCell
{
   UIImage   *theHighlightedImage;
   UIImage   *theImage;
   BOOL      flag;
   
   memset( ctxt, 0, sizeof( *ctxt));
   flag = [theCollectionViewCell isHighlighted];
   
   [theCollectionViewCell setHighlighted:NO];
   theImage = [theCollectionViewCell renderedImage];

   [theCollectionViewCell setHighlighted:YES];
   theHighlightedImage = [theCollectionViewCell renderedImage];

   [theCollectionViewCell setHighlighted:flag];
   
   ctxt->theImageView = [[UIImageView alloc] initWithImage:theImage];
   [ctxt->theImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];    // Not using constraints, lets auto resizing mask be translated automatically...
   
   ctxt->theHighlightedImageView = [[UIImageView alloc] initWithImage:theHighlightedImage];
   [ctxt->theHighlightedImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];    // Not using constraints, lets auto resizing mask be translated automatically...
   
   ctxt->theView =
   [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(theCollectionViewCell.frame),
                                            CGRectGetMinY(theCollectionViewCell.frame),
                                            CGRectGetWidth(ctxt->theImageView.frame),
                                            CGRectGetHeight(ctxt->theImageView.frame))];
   
   [ctxt->theView addSubview:ctxt->theImageView];
   [ctxt->theView addSubview:ctxt->theHighlightedImageView];
}


- (id <LXReorderableCollectionViewDelegateFlowLayout>) lxDelegate
{
   id   delegate;
   
   delegate = (id <LXReorderableCollectionViewDelegateFlowLayout> ) [[self collectionView] delegate];
   if( ! [delegate conformsToProtocol:@protocol( LXReorderableCollectionViewDelegateFlowLayout )])
      return( nil);
   return( delegate);
}



- (void) highlight:(reorder_views_context *) ctxt
{
   [ctxt->theView setTransform:CGAffineTransformMakeScale( 1.1f, 1.1f)];
   [ctxt->theImageView setAlpha:1.0f];
   [ctxt->theHighlightedImageView setAlpha:0.0f];
}


- (void) finishHighlighting:(reorder_views_context *) ctxt
           withSelectedPath:(NSIndexPath *) selectedPath
{
   id <LXReorderableCollectionViewDelegateFlowLayout>   delegate;
   
   [ctxt->theHighlightedImageView removeFromSuperview];

   delegate = [self lxDelegate];
   if( [delegate respondsToSelector:@selector( collectionView:layout:didBeginReorderingAtIndexPath: )])
      [delegate collectionView:[self collectionView]
                        layout:self
 didBeginReorderingAtIndexPath:selectedPath];
}


- (void) animateCurrentViewWithSelectedPath:(NSIndexPath *) selectedPath
{
   UICollectionViewLayoutAttributes   *attributes;
   
   attributes = [self layoutAttributesForItemAtIndexPath:selectedPath];
   
   [currentView_ setTransform:CGAffineTransformMakeScale( 1.0f, 1.0f)];
   [currentView_ setCenter:[attributes center]];
}


- (void) animationCompletedWithSelectedPath:(NSIndexPath *) selectedPath
{
   id <LXReorderableCollectionViewDelegateFlowLayout>   delegate;
   UICollectionView    *collectionView;
   
   [[self retain] autorelease]; // voodoo, because of strong/weak voodoo in original code
   
   collectionView = [self collectionView];
   [currentView_ removeFromSuperview];
   currentView_ = nil;
   
   [self invalidateLayout];
   
   delegate = [self lxDelegate];
   if( [delegate respondsToSelector:@selector( collectionView:layout:didEndReorderingAtIndexPath: )])
         [delegate collectionView:collectionView
                           layout:self
      didEndReorderingAtIndexPath:selectedPath];
}


- (void) handleLongPressGesture:(UILongPressGestureRecognizer *) recognizer
{
   NSIndexPath             *selectedPath;
   UICollectionView        *collectionView;
   UICollectionViewCell    *theCollectionViewCell;
   reorder_views_context   ctxt;
   CGPoint                 location;
   id <LXReorderableCollectionViewDelegateFlowLayout>   delegate;
   
   collectionView = [self collectionView];
   
   switch( [recognizer state])
   {
   case UIGestureRecognizerStateBegan:
      location     = [recognizer locationInView:self.collectionView];
      selectedPath = [collectionView indexPathForItemAtPoint:location];
      delegate     = [self lxDelegate];
         
      if( [delegate respondsToSelector:@selector( collectionView:layout:shouldBeginReorderingAtIndexPath:)])
      {
         if( ! [delegate collectionView:collectionView
                                 layout:self
       shouldBeginReorderingAtIndexPath:selectedPath])
            return;
      }
      
      if( [delegate respondsToSelector:@selector( collectionView:layout:willBeginReorderingAtIndexPath:)])
      {
         [delegate collectionView:collectionView
                           layout:self
   willBeginReorderingAtIndexPath:selectedPath];
      }
         
      theCollectionViewCell = [[self collectionView] cellForItemAtIndexPath:selectedPath];
       
      [self constructViews:&ctxt
                  withCell:theCollectionViewCell];
         
      [[self collectionView] addSubview:ctxt.theView];

      // ugh!
      [self->selectedItemIndexPath_ autorelease];
      self->selectedItemIndexPath_ = [selectedPath copy];

      self->currentView_           = ctxt.theView;
      self->currentViewCenter_     = [ctxt.theView center];

      [ctxt.theImageView setAlpha:0.0f];
      [ctxt.theHighlightedImageView setAlpha:1.0f];

        
      [UIView animateWithDuration:0.3
                       animations:^{ [self highlight:(void *) &ctxt];}
                       completion:^(BOOL finished)
                                   {
                                     [self finishHighlighting:(void *) &ctxt
                                             withSelectedPath:selectedPath];
                                   }];

      [self invalidateLayout];
         
      break;

   case UIGestureRecognizerStateEnded:
      selectedPath = selectedItemIndexPath_;
      delegate     = [self lxDelegate];
         
      if( [delegate respondsToSelector:@selector( collectionView:layout:willEndReorderingAtIndexPath: )])
         [delegate collectionView:self.collectionView
                           layout:self
     willEndReorderingAtIndexPath:selectedPath];

      [self->selectedItemIndexPath_ autorelease];
      self->selectedItemIndexPath_ = nil;
      self->currentViewCenter_     = CGPointZero;

      if( selectedPath)
      {
         [UIView animateWithDuration:0.3f
                          animations:^{ [self animateCurrentViewWithSelectedPath:selectedPath]; }
                          completion:^(BOOL finished) { [self animationCompletedWithSelectedPath:selectedPath]; }];
      }
      break;

   default:
      break;
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
      translation = [recognizer translationInView:self.collectionView];

      location    = LXS_CGPointAdd( currentViewCenter_,
                                    panTranslationInCollectionView_);

      panTranslationInCollectionView_ = translation;
      [currentView_ setCenter:location];
      
      [self invalidateLayoutIfNecessary];
   
      insets         = triggerScrollingEdgeInsets_;
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
   
   if( ! alwaysScroll_)
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
   if( [panGestureRecognizer_ isEqual:recognizer])
      return( selectedItemIndexPath_ != nil);

   return( YES);
}


- (BOOL) gestureRecognizer:(UIGestureRecognizer *) recognizer
   shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *) other
{
   if( [longPressGestureRecognizer_ isEqual:recognizer])
      return( [panGestureRecognizer_ isEqual:other]);
   
   if( [panGestureRecognizer_ isEqual:recognizer])
      return( [longPressGestureRecognizer_ isEqual:other]);
   
   return( NO);
}

@end

