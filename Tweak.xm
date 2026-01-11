#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>

// Definim tipurile de functii Unity de care avem nevoie
typedef void* (*il2cpp_domain_get_t)();
typedef void* (*il2cpp_domain_get_assemblies_t)(void* domain, size_t* size);
typedef void* (*il2cpp_class_from_name_t)(void* image, const char* namespaze, const char* name);
typedef void* (*il2cpp_class_get_method_from_name_t)(void* klass, const char* name, int argsCount);

void activate_ultra_igarashi() {
    // Incarcam libraria principala a Unity unde se afla toate functiile
    void* handle = dlopen(NULL, RTLD_NOW);
    
    // Gasim functiile de baza ale motorului Unity
    il2cpp_class_from_name_t class_from_name = (il2cpp_class_from_name_t)dlsym(handle, "il2cpp_class_from_name");
    il2cpp_class_get_method_from_name_t get_method = (il2cpp_class_get_method_from_name_t)dlsym(handle, "il2cpp_class_get_method_from_name");
    
    // 1. Cautam clasa Camera si functia de Aimbot din pozele tale
    // Nu folosim offset-ul 4719957, lasam Unity sa il gaseasca
    void* klass_camera = class_from_name(NULL, "UnityEngine", "Camera");
    if (klass_camera) {
        void* method_aim = get_method(klass_camera, "GetLocalSpaceAim_Injected", -1);
        if (method_aim) {
            // Aici aplicam patch-ul direct pe adresa gasita dinamic
            uintptr_t target_addr = *(uintptr_t*)method_aim; 
            uint32_t patch = 0xD65F03C0;
            vm_protect(mach_task_self(), (vm_address_t)target_addr, 4, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
            memcpy((void*)target_addr, &patch, 4);
            vm_protect(mach_task_self(), (vm_address_t)target_addr, 4, false, VM_PROT_READ | VM_PROT_EXECUTE);
        }
    }
}

%hook UIApplication
- (void)finishedTest:(id)arg1 extraResults:(id)arg2 {
    %orig;
    // Delay-ul tau de 60 de secunde
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        activate_ultra_igarashi();
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState Igarashi" 
            message:@"Metoda fara offset activata prin Unity Reflection!" 
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}
%end
