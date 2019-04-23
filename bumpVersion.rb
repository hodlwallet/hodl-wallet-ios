# dependencies: gem install xcodeproj
# 
# invocation: ruby bumpVersion.rb
#
# This will increment the CFBundleVersion of all of the required targets by one
# 
require 'xcodeproj'
project_path = './hodlwallet.xcodeproj'
project = Xcodeproj::Project.open(project_path)

desiredTargets = ['hodlwallet', 'hodlwallet WatchKit Extension', 'hodlwallet WatchKit App', 'TodayExtension', 'NotificationServiceExtension', 'MessagesExtension']
targets = project.native_targets.select do |target|
  desiredTargets.include? target.name
end

currentVersion = nil
currentShortVersion = nil
targets.each do |target|
  info_plist_path = target.build_configurations.first.build_settings["INFOPLIST_FILE"]
  plist = Xcodeproj::Plist.read_from_path(info_plist_path)
  if currentVersion == nil
    currentVersion = plist['CFBundleVersion']
  end

  if currentShortVersion == nil
    currentShortVersion = plist['CFBundleShortVersionString']
  end

  plist['CFBundleVersion'] = (currentVersion.to_i + 1).to_s
  plist['CFBundleShortVersionString'] = currentShortVersion.split('.').first(currentShortVersion.split('.').count - 1).join('.') + '.' + (currentShortVersion.split('.').last.to_i + 1).to_s
  Xcodeproj::Plist.write_to_path(plist, info_plist_path)
end
