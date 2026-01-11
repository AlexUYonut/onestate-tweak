#import <UIKit/UIKit.h>

%hook UIApplication
- (void)finishedTest:(id)arg1 extraResults:(id)arg2 {
    %orig;

    // Așteptăm 30 de secunde pentru a trece de scanarea de start a jocului
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        
        if (window) {
            // Desenăm un punct roșu (Crosshair/ESP Test) ca strat extern
            // Această metodă NU modifică adresa 4719eee, deci nu dă crash
            UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(window.bounds.size.width/2 - 5, window.bounds.size.height/2 - 5, 10, 10)];
            dot.backgroundColor = [UIColor redColor];
            dot.layer.cornerRadius = 5;
            dot.userInteractionEnabled = NO; 
            [window addSubview:dot];

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState Ghost" 
                message:@"Metoda invizibila activata! Build reusit." 
                preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
%end
