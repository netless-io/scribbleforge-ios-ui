Pod::Spec.new do |s|
  s.name = 'ScribbleForgeUI'
  s.version = '0.1.1'
  s.summary = 'UIKit UI components for ScribbleForge whiteboard.'
  s.description = <<-DESC
ScribbleForgeUI provides UIKit-based UI components for embedding the ScribbleForge
whiteboard and toolbar into client apps without modifying the core SDK.
  DESC
  s.homepage = 'https://github.com/netless-io/scribbleforge-ios-ui'
  s.license = { :type => 'Proprietary', :text => 'Copyright (c) 2026 Agora' }
  s.author = { 'Vince' => 'zjxuyunshi@gmail.com' }
  s.source = { :git => 'https://github.com/netless-io/scribbleforge-ios-ui.git', :tag => s.version.to_s }

  s.platform = :ios, '13.0'
  s.swift_versions = ['5.0']

  s.source_files = 'Sources/ScribbleForgeUI/**/*.{swift}'
  s.resource_bundles = { 'ScribbleForgeUI' => ['Sources/Resources/**/*.xcassets'] }
  s.frameworks = 'UIKit', 'Foundation'

  s.dependency 'ScribbleForge', '~> 1.1.1'
end
