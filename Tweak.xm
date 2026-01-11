#import <UIKit/UIKit.h>

%hook UIApplication
- (void)finishedTest:(id)arg1 extraResults:(id)arg2 {
    %orig;

    // Asteptam 30 de secunde sa se incarce harta
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // Cautam fereastra jocului intr-un mod care nu da eroare la build
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        
        if (window) {
            // Cream un punct de test (un mic cerc rosu) care sa stea DEASUPRA jocului
            UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(window.bounds.size.width/2 - 5, window.bounds.size.height/2 - 5, 10, 10)];
            dot.backgroundColor = [UIColor redColor];
            dot.layer.cornerRadius = 5;
            dot.userInteractionEnabled = NO; // Sa poti apasa prin el in joc
            [window addSubview:dot];

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState Ghost" 
                message:@"Sistemul de desenare extern este activ. Daca nu ai crash, metoda e sigura!" 
                preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
%end
