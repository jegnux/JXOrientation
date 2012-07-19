# JXOrientation

JXOrientation let you easily manage UIView properties depending on device orientation.

It works almost as the same way as the UIAppearance proxy object : 
You set a property for a specific orientation and changes will apply automaticaly on device rotations.

No need to override any UIViewController methods.


## How it works ?
 
Just use one of the proxy object on any UIView or UIView subclass

```objective-c
- (id) portrait;
- (id) portraitStraight;
- (id) portraitUpsideDown;
- (id) landscape;
- (id) landscapeLeft;
- (id) landscapeRight;
```

And send it any message that the receiver can handle. It will be really sent on orientation changes.

Exemples : 
```objective-c
- (void)viewDidLoad
{
    [super viewDidLoad];

    [[orientationLabel portraitStraight] setText:@"Portrait"];
    [[orientationLabel portraitUpsideDown] setText:@"Portrait Upside Down"];
    [[orientationLabel landscapeLeft] setText:@"Landscape Left"];
    [[orientationLabel landscapeRight] setText:@"Landscape Right"];
 
    [[imageView portrait] setCenter:CGPointMake(140., 280.)];
    [[imageView landscape] setCenter:CGPointMake(240., 160.)];
    
    [[textView portrait] setFrame:CGRectMake(CGRectGetMaxX(orientationLabel.frame), 20., 130., 230.)];
    [[textView landscape] setFrame:CGRectMake(20., CGRectGetMaxY(orientationLabel.frame), 150., 250.)];
    
    [[textView portrait] setBackgroundColor:[UIColor whiteColor]];
    [[textView landscape] setBackgroundColor:[UIColor blackColor]];
    
    [[textView portrait] setTextColor:[UIColor blackColor]];
    [[textView landscape] setTextColor:[UIColor whiteColor]];
    
    [[separatorView portrait] setHidden:NO];
    [[separatorView landscape] setHidden:YES];
    
    [[wrapperView portrait] setFrame:CGRectZero];
    [[wrapperView landscape] setFrame:CGRectMake(310., CGRectGetMaxY(orientationLabel.frame), 150., 150.)];
}
```