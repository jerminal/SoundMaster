SoundMaster
===========
 
Ultra simple game audio engine for iOS. The most useful features in one box. 

Features:
--------
1. Music fade in/out.
2. Cross-fade between two music tracks (you can also make a smooth transition between two loops)
3. Playing multiple sounds simultaneously.
4. Setting relative volume for specific sounds.
5. Pause, resume and loop music
6. Optimal memory usage.
7. Preloading music and sounds for best performance.
8. You can look for other features in api.

What’s In The Box:
--------
1. SoundMaster class.
2. Example iPhone project.

Configuration (iOS 5.0 and higher, ARC)
--------------
1. Drag SoundMaster folder to your project.
2. Add AVFoundation framework to your project’s target.
3. Import «SoundMaster.h» to use engine.

Supported Formats
-------------------

For best results use .caf files. You can convert your music files to .caf format using afconvert utility.

For background music (mono):

	afconvert -f caff -d aac -c 1 {input_file_name} {output_file_name}.caf

For background music (stereo):

 afconvert -f caff -d aac {input_file_name} {output_file_name}.caf

For sound effects (mono):

	afconvert -f caff -d ima4 -c 1 {input_file_name} {output_file_name}.caf

For sound effects (stereo):

	afconvert -f caff -d ima4 {input_file_name} {output_file_name}.caf

Issues
------
Please, inform us about bugs or ideas in [Issues](https://github.com/jerminal/SoundMaster/issues).
