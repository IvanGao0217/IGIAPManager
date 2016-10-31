Pod::Spec.new do |s|
  s.name         = 'IGIAPManager'
  s.version      = '0.0.2'
  s.summary      = 'A simple swift manger to mange your IAP.'
  s.homepage     = 'https://github.com/IvanGao0217/IGIAPManager'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'IvanGao' => 'ivangao0217@gmail.com (mailto:ivangao0217@gmail.com)'}
  s.ios.deployment_target = '10.0'
  s.source       = { :git => 'https://github.com/IvanGao0217/IGIAPManager.git', :tag => "#{s.version}" }
  s.source_files  = "IGIAPManager.swift"
end
