.PHONY: run run-pods run-spm spm-validate

run: run-pods

run-pods:
	cd Demo && pod install
	open Demo/ScribbleForgeSampleUI.xcworkspace

run-spm:
	open DemoSPM/ScribbleForgeSampleUI-SPM.xcodeproj

spm-validate:
	swift package dump-package
	swift package resolve
