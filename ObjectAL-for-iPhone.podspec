Pod::Spec.new do |s|
  s.name     = 'ObjectAL-for-iPhone'
  s.version  = '2.1.1'
  s.license  = { :type => 'Apache 2.0', :file => 'ObjectAL/ObjectAL/LICENSE.ObjectAL.txt' }
  s.summary  = 'Mac and iOS Audio, minus the headache.'
  s.homepage = 'http://kstenerud.github.io/ObjectAL-for-iPhone/'
  s.authors  = { 'Karl Stenerud' => 'kstenerud@gmail.com' }
  s.source   = { :git => 'https://github.com/kstenerud/ObjectAL-for-iPhone.git', :commit => '822c82ef5557523836e56e24a5e4f6b0b4bb35a6' }
  # s.source   = { :git => 'https://github.com/kstenerud/ObjectAL-for-iPhone.git', :tag => '2.1.1' }
  s.source_files = 'ObjectAL/**/*.[chm}'
  s.public_header_files = '*.h'
  s.requires_arc = false
  s.platform     = :ios, '3.0'
  s.ios.deployment_target = '3.0'
  s.ios.frameworks = 'OpenAL', 'AudioToolbox', 'AVFoundation'
end
