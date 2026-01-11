#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

void flash_patch(uintptr_t offset, uint32_t patch_data, uint32_t original_data) {
    uintptr_t address = _dyld_get_image_vmaddr_slide(0) + offset;
    
    // Pas 1: Aplicam Hack-ul
    vm_protect(mach_task_self(), (vm_address_t)address, 4, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    *(uint32_t *)address = patch_data;
    vm_protect(mach_task_self(), (vm_address_t)address, 4, false, VM_PROT_READ | VM_PROT_EXECUTE);

    // Pas 2: Dupa 0.5 secunde punem codul original inapoi
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        vm_protect(mach_task_self(), (vm_address_t)address, 4, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
        *(uint32_t *)address = original_data;
        vm_protect(mach_task_self(), (vm_address_t)address, 4, false, VM_PROT_READ | VM_PROT_EXECUTE);
    });
}

%hook UIApplication
- (void)finishedTest:(id)arg1 extraResults:(id)arg2 {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // Aplicam flash pe ambele adrese din pozele tale
        // 0xD65F03C0 este Patch-ul, restul sunt datele originale extrase din motorul Unity
        
        flash_patch(0x480555, 0xD65F03C0, 0xA9BE4FF4); // Aimbot
        flash_patch(0x4804EE, 0xD65F03C0, 0xD10103FF); // ESP

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState Flash" 
            message:@"Hack activat si mascat cu succes!" 
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}
%end
