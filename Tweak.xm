#import <UIKit/UIKit.h>

%hook UIApplication
- (void)finishedTest:(id)arg1 extraResults:(id)arg2 {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        } else {
            window = [UIApplication sharedApplication].keyWindow;
        }
        
        if (window) {
            UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(window.bounds.size.width/2 - 5, window.bounds.size.height/2 - 5, 10, 10)];
            dot.backgroundColor = [UIColor redColor];
            dot.layer.cornerRadius = 5;
            dot.userInteractionEnabled = NO; 
            [window addSubview:dot];

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState Ultra" 
                message:@"Sistemul Overlay a pornit. Daca nu ai crash, suntem indetectabili." 
                preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
%end
