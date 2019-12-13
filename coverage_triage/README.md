This is the script used in MoonLight project to check whether a Google Fuzzer-test-suite (FTS) binary hits its interesting locations.
There are two main scripts:
* get\_source\_profile.sh : takes an input of an execution profile (default.profraw) from a binary against an input. Note that the binary needs to be
  compiled with -fprofile-instr-generate -fcoverage-mapping. Reused the env files mechanism (see sample\_env).
* get\_hit\_count.sh : takes an input the output directory if get\_source\_profile.sh and then grab the hit count information from the specified location.
It requires the source code tree to be available in the form of \<target\>\_src.


Example:
The result of fuzzing campaign is cmin\_1 and the target is jpeg\_turbo, and we want to see how many times the first seed in fuzzer01 hits the interesting location (jdmarker.c:659).
```
source jpeg_turbo_env
ln -s <JPEG SOURCE> jpeg_turbo_src
${COV_BIN} cmin_1/fuzzer01/queue/id:000000* # this will produce default.profraw
./get_source_profile.sh jpeg_turbo default  # default is because we are using default.profraw
./get_hit_count.sh jpeg_turbo_coverage jdmarker.c 659
```
