//
//  SUViewController.m
//  Wezi
//
//  Created by Evgeniy Karkan on 4/26/13.
//  Copyright (c) 2013 Sigma Ukraine. All rights reserved.
//

#import "KEViewController.h"
#import "SVProgressHUD.h"
#import "KEWeatherManager.h"
#import "KELocationManager.h"
#import "GradientView.h"
#import "KEObservation.h"
#import "KEWindowView.h"
#import "KEAfterAfterTommorowForecast.h"
#import "KEAfterTommorowForecast.h"
#import "KEMapViewController.h"
#import "KEAppDelegate.h"
#import "Place.h"
#import "KEDataManager.h"

@interface KEViewController () <UIScrollViewDelegate,KECoordinateFillProtocol>

  //@property (nonatomic,strong) NSMutableArray *cities;

@property (nonatomic,strong) KEWindowView *templateView;
@property (nonatomic) NSMutableArray *cityViewArray;

@property (nonatomic, strong ) KEObservation *geo;

@property (nonatomic, strong) KEMapViewController *mapViewController;

@property (nonatomic, strong ) NSMutableArray *addedLocationsArray;
@property (nonatomic, readwrite) BOOL isShownMapPopover;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSMutableArray *entityArrayCoreData;

@property (nonatomic, strong) NSMutableArray *viewWithCoreData;

@property (nonatomic, strong) CLLocation *loc;

@property (nonatomic, readwrite) BOOL pageControlBeingUsed;

@property (weak, nonatomic) IBOutlet UINavigationItem *bar;

@property (nonatomic, strong) KEDataManager *dataManager;

@end

@implementation KEViewController
@synthesize pageControl;

#pragma mark - UIViewController

- (void)prepareForLoading
{
    self.managedObjectContext = [self.dataManager managedObjectContextFromAppDelegate];
    
    NSError *error = nil;
    NSArray *places = [self.managedObjectContext executeFetchRequest:[self.dataManager requestWithEntityName:@"Place"]
                                                               error:&error];
    if ([places count] > 0) {
        NSUInteger counter = 1;
        for (Place *place in places) {
            NSLog(@"Long %f Latt %f",place.longitude, place.latitude);
            counter++;
        }
    }
    else {
        NSLog(@"Could not find any place");
    }
    
    self.entityArrayCoreData = [NSMutableArray arrayWithArray:places];
    self.viewWithCoreData = [[NSMutableArray alloc]init];
    
    NSLog(@"Places are %i  shtuki", [self.entityArrayCoreData count]);
    
    for (int i = 1; i <=[places count]; i++) {
        KEWindowView *aView = [KEWindowView returnWindowView];
        aView.frame = CGRectMake((self.scrollView.contentOffset.x + 1024 *i) +50, 50, 800, 400);
        [self.scrollView addSubview:aView];
        [self.viewWithCoreData addObject:aView];
        
        CLLocation *location = [[CLLocation alloc]initWithLatitude:[[places objectAtIndex:i-1] latitude] longitude:[[places objectAtIndex:i-1] longitude]];
        
        [self reloadDataWithNewLocation:location withView:aView];
    }
    
    self.pageControl.numberOfPages = [places count]+1 ;
    self.scrollView.contentSize = CGSizeMake(1024 * ([places count]+1), self.scrollView.contentSize.height);
}


- (void)viewDidLoad
{
    
     NSLog(@"self.scrollView.frame.size.width %f", self.scrollView.frame.size.width);
    
    [super viewDidLoad];
    [self setupViews];
    
    
    
    KEWeatherManager *weather = [KEWeatherManager sharedClient];
    weather.delegate = self;
    
    __weak KEViewController *weakSelf = self;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kLocationDidChangeNotificationKey
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      NSLog(@"Note: %@", note);
                                                      [weakSelf reloadData];
                                                  }];
    
    
    [[KELocationManager sharedManager] startMonitoringLocationChanges];
    
    self.scrollView.delegate = self;
	self.pageControl.currentPage = 0;
    [self.pageControl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventValueChanged];

    self.templateView = [KEWindowView returnWindowView];
    self.templateView.frame = CGRectMake(50, 50, 800, 400);
    
    [self.scrollView addSubview:self.templateView];
    
    self.mapViewController = [[KEMapViewController alloc]init];
    self.mapViewController.objectToDelegate = self;
    
    self.isShownMapPopover = NO;
    
//    NSString *string = @"http://icons-ak.wxug.com/i/c/k/clear.gif";
//    if ([string rangeOfString:@"nt_clear"].location == NSNotFound) {
//        NSLog(@"string does not contain bla");
//    } else {
//        NSLog(@"string contains bla!");
//    }
    
    NSString *string = @"http://icons-ak.wxug.com/i/c/k/clear.gif";
    if ([string rangeOfString:@"clearf"].location == NSNotFound) {
            NSLog(@"string does not contains bla!");
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didGetMyNotification)
                                                 name:@"Foo"
                                               object:nil];
    
    self.dataManager = [KEDataManager sharedDataManager];
    [self prepareForLoading];
}

- (void)didGetMyNotification
{
    NSLog(@"Received notification %p,",pageControl);
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"segPop"]) {
        self.currentPopoverSegue = (UIStoryboardPopoverSegue *)segue;
        self.mapViewController = [segue destinationViewController];
        [self.mapViewController setObjectToDelegate:self];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[KELocationManager sharedManager] stopMonitoringLocationChanges];
}

#pragma mark - Private

- (void)setupViews
{
    self.observationContainerView.clipsToBounds = YES;
    self.observationContainerView.layer.cornerRadius = 6.0f;
    self.observationContainerView.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.observationContainerView.layer.borderWidth  = 3.0f;
    
    self.shadowContainerView.backgroundColor = [UIColor clearColor];
    self.shadowContainerView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.shadowContainerView.layer.shadowOffset = CGSizeZero;
    self.shadowContainerView.layer.shadowOpacity = 0.65f;
    self.shadowContainerView.layer.shadowRadius = 4.0f;
    //self.shadowContainerView.hidden = YES;
    
}

- (void)updateUIWithObservationForCurrentLocation:(KEObservation *)observation
{
    if (observation) {
        
        self.shadowContainerView.hidden = NO;
    
//    if (!([observation.iconUrl rangeOfString:@"nt_clear"].location == NSNotFound )) {          // think how to add it to util or helper
//        [self.currentConditionImageView setImage:[UIImage imageNamed:@"images-2.jpeg"]];
//    }
//[self.currentConditionImageView setImageWithURL:[NSURL URLWithString:observation.iconUrl]];
        
        [self.weatherUndegroundImageView setImageWithURL:[NSURL URLWithString:observation.weatherUndergroundImageInfo[@"url"]]];
        
        self.locationLabel.text = observation.location[@"full"];
        self.currentTemperatureLabel.text = observation.temperatureDescription;
        //self.feelsLikeTemperatureLabel.text = [@"Feels like " stringByAppendingString:observation.feelsLikeTemperatureDescription];
        self.weatherDescriptionLabel.text = observation.weatherDescription;
        self.windDescriptionLabel.text = observation.windDescription;
        self.humidityLabel.text = observation.relativeHumidity;
        
        self.devointLabel.text = observation.dewpointDescription;
        self.lastUpdateLAbel.text = observation.timeString;
        
        [self.templateView.conditionIcon setImageWithURL:[NSURL URLWithString:observation.iconUrl]];
        self.templateView.currentTemperature.text = observation.temperatureDescription;
    }
    else {
        self.shadowContainerView.hidden = YES;
    }
}

- (void)updateUIForView:(KEWindowView *)viewtoUpdate observetion:(KEObservation *)observation
{
    if (observation) {
            
        [viewtoUpdate.conditionIcon setImageWithURL:[NSURL URLWithString:observation.iconUrl]];
        [viewtoUpdate.bigImage setImageWithURL:[NSURL URLWithString:observation.iconUrl]];
        viewtoUpdate.currentTemperature.text = observation.temperatureDescription;
        viewtoUpdate.wind.text = observation.windDescription;
        
        viewtoUpdate.place.text = observation.location[@"full"];
        
        KEAppDelegate *appDelegate = (KEAppDelegate *)[[UIApplication sharedApplication]delegate];
        self.managedObjectContext = [appDelegate managedObjectContext];
        
              
        viewtoUpdate.timeStamp.text = observation.timeString;
        
    }
}

#pragma -  i add it
//
- (void)updateTommorowWithForecast:(KETommorowForecast *)forecast withView:(KEWindowView *)viewToUpdate
{
    [viewToUpdate.tomorrowView setImageWithURL:[NSURL URLWithString:forecast.iconURL]];
    viewToUpdate.tommorowTemp.text = forecast.highTemperature;
    
//    NSLog(@"AfTom %@", forecast.conditionOnForecast  );
//    NSLog(@" %@", forecast.month  );
//    NSLog(@" %@", forecast.weekDay  );
//    NSLog(@" %@", forecast.dayNumber  );
//    NSLog(@" %@", forecast.yearNumber  );
//    NSLog(@" %@", forecast.humidity  );
//    NSLog(@" %@", forecast.wind  );
//    NSLog(@" %@", forecast.highTemperature  );
//    NSLog(@" %@", forecast.lowTemperature  );
}

- (void)updateAfterTomorrowWithForecast:(KEAfterTommorowForecast *)forecast withView:(KEWindowView *)viewToUpdate
{
    [viewToUpdate.afterTommorowView setImageWithURL:[NSURL URLWithString:forecast.iconURL]];
    viewToUpdate.afterTommorowTemp.text = forecast.highTemperature;

    
//    NSLog(@"AfTom %@", forecast.conditionOnForecast  );
//    NSLog(@" %@", forecast.month  );
//    NSLog(@" %@", forecast.weekDay  );
//    NSLog(@" %@", forecast.dayNumber  );
//    NSLog(@" %@", forecast.yearNumber  );
//    NSLog(@" %@", forecast.humidity  );
//    NSLog(@" %@", forecast.wind  );
//    NSLog(@" %@", forecast.highTemperature  );
//    NSLog(@" %@", forecast.lowTemperature  );
}

- (void)updateAfterAfterTommorowWithForecast:(KEAfterAfterTommorowForecast *)forecast withView:(KEWindowView *)viewToUpdate
{
    [viewToUpdate.afterAfterTommorowView setImageWithURL:[NSURL URLWithString:forecast.iconURL]];
    viewToUpdate.afrerAfterTommorowTemp.text = forecast.highTemperature;

    
//    NSLog(@"AfAfTom %@", forecast.conditionOnForecast  );
//    NSLog(@" %@", forecast.month  );
//    NSLog(@" %@", forecast.weekDay  );
//    NSLog(@" %@", forecast.dayNumber  );
//    NSLog(@" %@", forecast.yearNumber  );
//    NSLog(@" %@", forecast.humidity  );
//    NSLog(@" %@", forecast.wind  );
//    NSLog(@" %@", forecast.highTemperature  );
//    NSLog(@" %@", forecast.lowTemperature  );
}

- (void)reloadData
{
    KEWeatherManager *client = [KEWeatherManager sharedClient];
    CLLocation *location = [[KELocationManager sharedManager] currentLocation];
    
    [SVProgressHUD show];
    
    __weak KEViewController *weakSelf = self;
    
    [client getCurrentWeatherObservationForLocation:location completion:^(KEObservation *observation, NSError *error) {
        if (error) {
            NSLog(@"Web Service Error: %@", [error description]);
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        }
        else {
            [weakSelf updateUIWithObservationForCurrentLocation:observation];
        }
            //[SVProgressHUD dismiss];
            [SVProgressHUD showSuccessWithStatus:@"Ok!!!"];
    }];
    
    [client getForecastObservationForLocation:location completion:^(NSMutableDictionary *days, NSError *error) {
        if (error) {
            NSLog(@"Web Service Error: %@", [error description]);
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        }
        else {
            [weakSelf updateTommorowWithForecast:[days valueForKey:@"Tommorow"] withView:self.templateView];
            [weakSelf updateAfterTomorrowWithForecast:[days valueForKey:@"AfterTommorow"] withView:self.templateView];
            [weakSelf updateAfterAfterTommorowWithForecast:[days valueForKey:@"AfterAfterTommorow"] withView:self.templateView];
        }
    }];
}

- (void)reloadDataWithNewLocation:(CLLocation *)newLocation withView:(KEWindowView *)viewToUpdate
{
    KEWeatherManager *client = [KEWeatherManager sharedClient];
    [SVProgressHUD show];
    
    __weak KEViewController *weakSelf = self;
    
     [client getCurrentWeatherObservationForLocation:newLocation completion:^(KEObservation *observation, NSError *error) {
        
        if (error) {
            NSLog(@"Web Service Error: %@", [error description]);
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        }
        else {
            [weakSelf updateUIForView:viewToUpdate observetion:observation];
        }
        [SVProgressHUD dismiss];
    }];
    
    [client getForecastObservationForLocation:newLocation completion:^(NSMutableDictionary *days, NSError *error) {
        if (error) {
            NSLog(@"Web Service Error: %@", [error description]);
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        }
        else {
            [weakSelf updateTommorowWithForecast:[days valueForKey:@"Tommorow"] withView:viewToUpdate];
            [weakSelf updateAfterTomorrowWithForecast:[days valueForKey:@"AfterTommorow"] withView:viewToUpdate];
            [weakSelf updateAfterAfterTommorowWithForecast:[days valueForKey:@"AfterAfterTommorow"] withView:viewToUpdate];
        }
    }];
}

- (void)fillArrayWithCoordinate:(CLLocation *)location
{
    //addedLocationsArray = [[NSMutableArray alloc]init];
    [self.addedLocationsArray addObject:location];
    
    NSLog(@"Description %lu", (unsigned long)[self.addedLocationsArray count]);
    [[self.currentPopoverSegue popoverController] dismissPopoverAnimated: YES];
    self.isShownMapPopover = NO;
}

#pragma mark - Actions
- (IBAction)changePage:(id)sender {    
    
    [self.scrollView setContentOffset:CGPointMake(1024*self.pageControl.currentPage, 0) animated:YES];
    
    self.pageControlBeingUsed = YES;
}

- (IBAction)goToMap:(id)sender {
    
    if (!self.isShownMapPopover) {
        [self performSegueWithIdentifier:@"segPop" sender:self];
        self.isShownMapPopover = YES;
    }
}

- (IBAction)refresh:(id)sender {
    
        [self reloadData];
        
        if (self.pageControl.currentPage != 0) {
            
            KEAppDelegate *appDelegate = (KEAppDelegate *)[[UIApplication sharedApplication]delegate];
            self.managedObjectContext = [appDelegate managedObjectContext];
            
            NSFetchRequest *fetchRequst = [[NSFetchRequest alloc]init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Place" inManagedObjectContext:self.managedObjectContext];
            [fetchRequst setEntity:entity];
            
            NSError *error = nil;
            NSArray *places = [self.managedObjectContext executeFetchRequest:fetchRequst error:&error];
            
            self.entityArrayCoreData = [NSMutableArray arrayWithArray:places];
            
            self.loc = [[CLLocation alloc]initWithLatitude:[[self.entityArrayCoreData objectAtIndex:self.pageControl.currentPage - 1] latitude]
                                                 longitude:[[self.entityArrayCoreData objectAtIndex:self.pageControl.currentPage - 1] longitude]];
             
            if (self.pageControl.currentPage == [self.entityArrayCoreData count]) {
                
                [self reloadDataWithNewLocation:self.loc withView:[self.viewWithCoreData objectAtIndex:self.pageControl.currentPage-1]];
            }
            else {
                [self reloadDataWithNewLocation:self.loc withView:[self.viewWithCoreData objectAtIndex:self.pageControl.currentPage-1]];
            }
        }
}

- (void)addPressedWithCoordinate:(CLLocation *)location 
{
    if ([self.entityArrayCoreData count] == 0) {
        [self.entityArrayCoreData addObject:location];
    }
 
    [[self.currentPopoverSegue popoverController] dismissPopoverAnimated: YES];
    self.isShownMapPopover = NO;
        
    if (self.pageControl.numberOfPages == 20) {
        [SVProgressHUD showErrorWithStatus:@"Oops.. Sorry Maximum 20 cities"];
        return;
    }
    if (self.pageControl.numberOfPages < 20) {
        self.pageControl.numberOfPages += 1;
    }    
    if (self.pageControl.numberOfPages == 2) {
        
        KEWindowView *foo = [KEWindowView returnWindowView];
        foo.frame = CGRectMake(1074, 50, 800, 400);
        [self.scrollView addSubview:foo];
        [self.viewWithCoreData addObject:foo];
        
        if ([self.entityArrayCoreData count] == 1) {
            [self.entityArrayCoreData addObject:location];
        }
     
        dispatch_queue_t dummyQueue = dispatch_queue_create("dummyQueue", nil);
        dispatch_async(dummyQueue, ^{
            [self reloadDataWithNewLocation:location withView:foo];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
            [self.scrollView setContentOffset:CGPointMake(1024, 0) animated:YES];
        });
    }    
    else if (self.pageControl.numberOfPages > 2) {
        
        [self.entityArrayCoreData addObject:location];
         NSLog(@"Description now %lu", (unsigned long)[self.entityArrayCoreData count]);
        
        KEWindowView *bar = [KEWindowView returnWindowView];
        
        if (self.pageControl.currentPage == self.pageControl.numberOfPages - 2) {
            bar.frame = CGRectMake((self.scrollView.contentOffset.x + 1074), 50, 800, 400);
        }
        else {
            bar.frame = CGRectMake((self.scrollView.contentOffset.x + 1024 * (self.pageControl.numberOfPages - self.pageControl.currentPage - 1) +50), 50, 800, 400);
        }
        
        [self.scrollView addSubview:bar];
        [self.viewWithCoreData addObject:bar];
        
        dispatch_queue_t dummyQueue = dispatch_queue_create("dummyQueue", nil);
        dispatch_async(dummyQueue, ^{
            [self reloadDataWithNewLocation:location withView:bar];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
            [self.scrollView setContentOffset:CGPointMake(1024 * (self.pageControl.numberOfPages - 1),0) animated:YES];
            self.pageControl.currentPage = self.pageControl.numberOfPages - 1;
        });
    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.pageControl.numberOfPages, self.scrollView.frame.size.height);
}

- (IBAction)deletePAge:(id)sender
{
    if (self.pageControl.currentPage != 0) {
        [[self.viewWithCoreData objectAtIndex:self.pageControl.currentPage-1 ] removeFromSuperview];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
                 
        for (UIView *dummyObject in self.viewWithCoreData) {
            NSUInteger index = [self.viewWithCoreData indexOfObject:dummyObject];
            if ((index > self.pageControl.currentPage -1) && (self.pageControl.currentPage != 0)) {
                CGRect fullScreenRect = CGRectMake(dummyObject.frame.origin.x - 1024, 50, 800, 400);
                [dummyObject setFrame:fullScreenRect];
            }
        }
        if (self.pageControl.currentPage != 0) {
            [self.viewWithCoreData removeObjectAtIndex:self.pageControl.currentPage -1];
            [self.entityArrayCoreData removeObjectAtIndex:self.pageControl.currentPage -1];  //worked code
                                                                                                                     // taking entity
            NSFetchRequest *fetchRequst = [[NSFetchRequest alloc]init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Place" inManagedObjectContext:self.managedObjectContext];
            [fetchRequst setEntity:entity];
            
            NSError *error = nil;
            NSArray *places = [self.managedObjectContext executeFetchRequest:fetchRequst error:&error];
            if ([places count] > 0) {
                Place *aPlace = [places objectAtIndex:self.pageControl.currentPage-1];
                [self.managedObjectContext deleteObject:aPlace];
                
                NSError *savingError = nil;
                if ([self.managedObjectContext save:&savingError]) {
                    NSLog(@"Successfully delete object");
                    NSLog(@"Array of entity is %@", [places description]);
                    self.entityArrayCoreData = [NSMutableArray arrayWithArray:places];
                }
                else {
                    NSLog(@"Fail to delete ");
                }
            }
            else {
                NSLog(@"Could not find entiyt in context");
           }
        }
        self.pageControl.numberOfPages = [self.viewWithCoreData count]+1;
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.pageControl.numberOfPages, self.scrollView.frame.size.height);
    }];
}

#pragma mark - ScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    if (!self.pageControlBeingUsed) {
    // Update the page when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
        NSLog (@" PAGE IS %ld", (long)self.pageControl.currentPage);
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	self.pageControlBeingUsed = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	self.pageControlBeingUsed = NO;
}

#pragma mark - iOS 5.1 support 

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
    return NO;
}

- (void)viewDidUnload {
    [self setBar:nil];
    [super viewDidUnload];
}
@end
