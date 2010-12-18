//
//  CanvasView.m
//  CanvasKit
//
//  Created by JM on 15/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CanvasView.h"

@interface CanvasView()
- (void) reconfigurePageViewIndexes;	
- (void) refreshTiles;
- (void) initTileDimensionsForBoundsSize:(CGSize) boundsSize;
@end


@implementation CanvasView

#define kMarginMinimum CGSizeMake(10.,10.)

@synthesize previousPagePlaceholder = previousPagePlaceholder_;
@synthesize currentPagePlaceholder = currentPagePlaceholder_;
@synthesize nextPagePlaceholder = nextPagePlaceholder_;
@synthesize datasource = datasource_;
@synthesize canvasControlDelegate = canvasControlDelegate_;
@synthesize page;

static int nColumns;
static int nRows;
static CGSize tileMargin;
static int tilesPerPage;
static CGSize tileSize;
static CGSize pageMargin;


- (id)initWithFrame:(CGRect)frame withDataSource:(id<CanvasDataSourceProtocol>) datasource
{    
    self = [super initWithFrame:frame];
    if (self) 
	{
		self.delegate = self;
		self.datasource = datasource;
		self.backgroundColor = [UIColor blackColor];
		self.pagingEnabled = YES;
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
		self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
		self.autoresizesSubviews = YES;
		self.contentMode = UIViewContentModeScaleAspectFill;
		self.page = 0;
		areDimensionsUpdated_ = NO;
		
		previousPagePlaceholder_ = [[CanvasPagePlaceholder alloc] initWithFrame:frame withLabel:@"Left"];
		currentPagePlaceholder_ = [[CanvasPagePlaceholder alloc] initWithFrame:frame withLabel:@"Center"];
		nextPagePlaceholder_ = [[CanvasPagePlaceholder alloc] initWithFrame:frame withLabel:@"Right"];
		
		[self addSubview:previousPagePlaceholder_];
		[self addSubview:currentPagePlaceholder_];
		[self addSubview:nextPagePlaceholder_];

		[self resetDimensions];
		
    }
    return self;
}

- (void) setNeedsLayout
{
	[super setNeedsLayout];
	areDimensionsUpdated_ = NO;
}

- (void) resetDimensions
{
	[UIView beginAnimations:@"canvasDimensionChange" context:nil];
	NSLog(@"reseting dimensions");
	CGSize boundSize = self.bounds.size;

	[self initTileDimensionsForBoundsSize:boundSize];
	
	// create enough scroll space for 3 page panels (prev, current, next)
	self.contentSize = CGSizeMake(boundSize.width * 3, boundSize.height);
	
	previousPagePlaceholder_.frame = CGRectMake(0, 0, boundSize.width, boundSize.height);
	currentPagePlaceholder_.frame = CGRectMake(boundSize.width, 0, boundSize.width, boundSize.height);
	nextPagePlaceholder_.frame = CGRectMake(boundSize.width * 2, 0, boundSize.width, boundSize.height);

	[self refreshTiles];	
	// set to offset to center page
	[self setContentOffset:CGPointMake(boundSize.width, 0)];
	
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self cache:YES];
//	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.8];
	[UIView commitAnimations];

}

- (void) initTileDimensionsForBoundsSize:(CGSize) boundsSize;
{
	tileSize = [self.datasource tileDimensions];
	pageMargin = [self.datasource pageMargin];
	boundsSize.width -= pageMargin.width * 2;
	boundsSize.height -= pageMargin.height * 2;
	nColumns = floor(boundsSize.width / (tileSize.width + kMarginMinimum.width));
	nRows = floor(boundsSize.height / (tileSize.height + kMarginMinimum.height));
	CGFloat marginHorizontal = (boundsSize.width - nColumns * tileSize.width) / (nColumns + 1);
	CGFloat marginVertical = (boundsSize.height - nRows * tileSize.height) / (nRows + 1);
	tileMargin = CGSizeMake(marginHorizontal, marginVertical);
	tilesPerPage = nColumns * nRows;
	NSLog(@"Cols: %d \t Rows: %d \t Tiles: %d", nColumns, nRows, tilesPerPage);	
}

- (void) layoutSubviews
{
	if (!areDimensionsUpdated_)
	{
		[self resetDimensions];
		areDimensionsUpdated_ = YES;
	}
	[super layoutSubviews];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
	self.previousPagePlaceholder = nil;
	self.currentPagePlaceholder = nil;
	self.nextPagePlaceholder = nil;
	self.datasource = nil;
	self.canvasControlDelegate = nil;
    [super dealloc];
}

//- (void) refreshTiles;
//{
//	self.currentPagePlaceholder.pageView.pageTileDictionaries = [self.datasource tileDictionariesForPage:self.page];
//	self.previousPagePlaceholder.pageView.pageTileDictionaries = [self.datasource tileDictionariesForPage:self.page - 1];
//	self.nextPagePlaceholder.pageView.pageTileDictionaries = [self.datasource tileDictionariesForPage:self.page + 1];
//	[self setNeedsDisplay];
//}

//- (void) snap

- (void) refreshTiles;
{
	[self reconfigurePageViewIndexes];
	[self.currentPagePlaceholder.pageView updateTilesWithDataSource:self.datasource];
	[self.nextPagePlaceholder.pageView updateTilesWithDataSource:self.datasource];
	[self.previousPagePlaceholder.pageView updateTilesWithDataSource:self.datasource];
}

- (void) reconfigurePageViewIndexes;
{
	self.currentPagePlaceholder.pageView.pageIndex = page;
	self.previousPagePlaceholder.pageView.pageIndex = page - 1;
	self.nextPagePlaceholder.pageView.pageIndex = page + 1;
}

- (void) pagedForward
{
	self.page++;
	
	CanvasPageView * oldViewCurrent = [self.currentPagePlaceholder.pageView retain];
	CanvasPageView * oldViewNext = [self.nextPagePlaceholder.pageView retain];
	CanvasPageView * oldViewPrevious = [self.previousPagePlaceholder.pageView retain];
	
	[oldViewCurrent removeFromSuperview];
	[oldViewNext removeFromSuperview];
	[oldViewPrevious removeFromSuperview];
	
	self.currentPagePlaceholder.pageView = oldViewNext;
	self.previousPagePlaceholder.pageView = oldViewCurrent;
	self.nextPagePlaceholder.pageView = oldViewPrevious;	

	[self.currentPagePlaceholder addSubview:self.currentPagePlaceholder.pageView];
	[self.previousPagePlaceholder addSubview:self.previousPagePlaceholder.pageView];
	[self.nextPagePlaceholder addSubview:self.nextPagePlaceholder.pageView];
	
	[self reconfigurePageViewIndexes];	
	
	[self.nextPagePlaceholder.pageView updateTilesWithDataSource:self.datasource];

	[oldViewCurrent release];
	[oldViewNext release];
	[oldViewPrevious release];
	[self.canvasControlDelegate canvasViewDidScrollNext:self];
	
	if ((self.page + 1) * tilesPerPage >= [self.datasource totalNumberOfTiles])
	{
		[self.canvasControlDelegate canvasViewDidScrollToLastPage:self];
//		[(id) self.canvasControlDelegate performSelector:@selector(canvasViewDidScrollToLastPage:) withObject:self];
	}


}

- (void) pagedBackward
{
	self.page--;

	CanvasPageView * oldViewCurrent = [self.currentPagePlaceholder.pageView retain];
	CanvasPageView * oldViewNext = [self.nextPagePlaceholder.pageView retain];
	CanvasPageView * oldViewPrevious = [self.previousPagePlaceholder.pageView retain];	
	
	[oldViewCurrent removeFromSuperview];
	[oldViewNext removeFromSuperview];
	[oldViewPrevious removeFromSuperview];
	
	self.currentPagePlaceholder.pageView = oldViewPrevious;
	self.previousPagePlaceholder.pageView = oldViewNext;
	self.nextPagePlaceholder.pageView = oldViewCurrent;	

	[self.currentPagePlaceholder addSubview:self.currentPagePlaceholder.pageView];
	[self.previousPagePlaceholder addSubview:self.previousPagePlaceholder.pageView];
	[self.nextPagePlaceholder addSubview:self.nextPagePlaceholder.pageView];
	
	[self reconfigurePageViewIndexes];

	[self.previousPagePlaceholder.pageView updateTilesWithDataSource:self.datasource];	
//	[oldViewCurrent setNeedsDisplay];
//	[oldViewNext setNeedsDisplay];
//	[oldViewPrevious setNeedsDisplay];
	
	[oldViewCurrent release];
	[oldViewNext release];
	[oldViewPrevious release];	
	
	[self.canvasControlDelegate canvasViewDidScrollPrevious:self];
}


- (void) scrollViewDidScroll:(UIScrollView *)scrollView;
{
    CGFloat pageWidth = self.frame.size.width;
	CGFloat leftThreshold = (pageWidth * 0.6);
	if (self.page <= 0 && self.contentOffset.x < leftThreshold)
	{
		[self setContentOffset:CGPointMake(leftThreshold, 0)];
	}
	else if (self.page <= 0 && self.contentOffset.x < pageWidth)
	{
		CGFloat scrollAlpha = 1. - (pageWidth - self.contentOffset.x) / (pageWidth - leftThreshold);
		if (scrollAlpha > 0.98)
		{
			scrollAlpha = 1.;
		}
		else if (scrollAlpha < 0.2)
		{
			scrollAlpha = 0.2;
		}
		self.previousPagePlaceholder.pageView.alpha = scrollAlpha;
	}	
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{	
    CGFloat pageWidth = self.frame.size.width;
	int newPage = floor((self.contentOffset.x - pageWidth / 2) / pageWidth) + self.page;
	if (newPage > self.page)
	{
		[self pagedForward];
		[self setContentOffset:CGPointMake(pageWidth, 0)];
	}
	else if (newPage < self.page)
	{
		[self pagedBackward];
		[self setContentOffset:CGPointMake(pageWidth, 0)];
	}
	else 
	{
		[self setContentOffset:CGPointMake(pageWidth, 0) animated:YES];
	}
}

#pragma mark -
#pragma mark Static Accessors for Subviews

+ (int) nColumns;
{
	return nColumns;
}

+ (int) nRows;
{
	return nRows;
}

+ (CGSize) pageMargin;
{
	return pageMargin;
}

+ (CGSize) tileMargin;
{
	return tileMargin;
}

+ (int) tilesPerPage;
{
	return tilesPerPage;
}

+ (CGSize) tileSize;
{
	return tileSize;
}

+ (CGRect) rectForTileAtIndex:(int) index;
{
	index = index % tilesPerPage;
	int row = floor(index / nColumns);
	int col = floor(index % nColumns);
	CGFloat locY = (row + 1) * tileMargin.height + (row * tileSize.height);
	CGFloat locX = (col + 1) * tileMargin.width + (col * tileSize.width);
	return CGRectMake(locX, locY, tileSize.width, tileSize.height);
}

@end