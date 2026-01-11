#import <UIKit/UIKit.h>

%hook UIApplication
- (void)finishedTest:(id)arg1 extraResults:(id)arg2 {
    %orig;

    // Așteptăm 30 de secunde să treacă verificările de start ale jocului
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // Căutăm fereastra principală a jocului
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        
        if (window) {
            // Desenăm un punct roșu în mijlocul ecranului (Crosshair/ESP Test)
            // Acesta este un strat extern, nu modifică fișierul OneState
            UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(window.bounds.size.width/2 - 5, window.bounds.size.height/2 - 5, 10, 10)];
            dot.backgroundColor = [UIColor redColor];
            dot.layer.cornerRadius = 5;
            dot.userInteractionEnabled = NO; // Permite să apeși butoanele din joc prin el
            [window addSubview:dot];

            // Alertă de confirmare
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState Ultra" 
                message:@"Sistemul Ghost (Overlay) activat cu succes!" 
                preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
%end
