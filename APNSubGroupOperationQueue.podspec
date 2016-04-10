Pod::Spec.new do |s|
    s.name         = "APNSubGroupOperationQueue"
    s.version      = "1.0.0"
    s.summary      = "Serial processing sub groups inside your concurrent NSOperationQueue."
    s.description  = "APNSubGroupOperationQueue is a µFramework consisting of `NSOperationQueue` subclasses (Swift & Obj-C) which allow scheduling operations in serial subgroups inside a concurrent queue"
    
    s.homepage         = "https://github.com/p4checo/APNSubGroupOperationQueue"
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    
    s.author           = { 'André Pacheco Neves' => 'p4checo + @ + gmail + . + com' }
    s.social_media_url = 'https://twitter.com/p4checo'
    
    s.ios.deployment_target = '8.0'
    s.osx.deployment_target = '10.9'
    s.tvos.deployment_target = '9.0'
    s.watchos.deployment_target = '2.0'
    
    s.source       = { :git => "https://github.com/p4checo/APNSubGroupOperationQueue.git", :tag => s.version }
    
    s.source_files = "Sources/**/SubGroupOperationQueue.{h,m,swift}"
    
    s.framework = "Foundation"
end