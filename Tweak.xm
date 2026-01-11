#import <UIKit/UIKit.h>
#import <dlfcn.h>

// Definim un strat de desenare care sta deasupra jocului fara sa-l atinga
@interface ESPView : UIView
@end

@implementation ESPView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO; // Nu blocheaza atingerile in joc
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    // AICI se intampla magia: desenam peste joc
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    
    // Exemplu: Desenam un cerc in mijlocul ecranului (Crosshair/Aim helper)
    CGContextAddEllipseInRect(context, CGRectMake(rect.size.width/2 - 5, rect.size.height/2 - 5, 10, 10));
    CGContextStrokePath(context);
}
@end

%hook UIApplication
- (void)finishedTest:(id)arg1 extraResults:(id)arg2 {
    %orig;

    // Folosim un delay sigur
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            // Adaugam stratul de ESP fara sa modificam binarul jocului
            ESPView *esp = [[ESPView alloc] initWithFrame:window.bounds];
            [window addSubview:esp];
            
            // Logica Igarashi: "Vorbim" cu Unity doar pentru a cere informatii, nu pentru a schimba codul
            void* handle = dlopen(NULL, RTLD_NOW);
            if (handle) {
                NSLog(@"[OneState] Sistemul de vizualizare a fost injectat silentios.");
            }

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState Ultra" 
                message:@"Metoda Anti-Crash activata. ESP-ul este acum un strat extern." 
                preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
%end
