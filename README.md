The scripts contained in this archive are used during the experiments, corpus preparation, and 
plotting figures from experiment data.

###################################################################################################
#                                      Corpus Preparation                                         #
###################################################################################################

There are various script that are involved with the corpus preparation.
The following two scripts are to ease the calling to manually calling afl-cmin or afl-showmap and 
passing individual parameter set. 
This is to be used in conjunction with the configuration files containing the environment parameters.
There are some sample configuration files in "sample\_env" 
Currently, the location of the configuration files is expected to be in the folder of ~/llvm\_asan/

To obtain the cmin corpus and afl tuples for further processing, execute the following:

cmin.sh <initial corpus> <program>
showmaps.sh <initial corpus> <program>

where initial corpus is the directory of the initial corpus, and program is the program which will
be used in fuzzing. It is limited by the configuration files, and currently it can take value from
the set of {pdf, sox, wav, tiff409, ttf253, svg24020, and xml290}.

The output from showmaps.sh is converted using MoonBeam to be bitvectors as input to MoonLight.
"moonlight\_call.sh" is a wrapper to ease the calling of MoonLight.
It takes as input the program and the weight type, either none which means unweighted, "size" which
means MoonLight will use file size as the weight, and "time" which means MoonLight will use execution
time as the weight.
The file size weight is obtained directly from the file information, or we can use "get\_size.sh".
The execution time weight is obtained by first executing "check\_timeout.sh", and then we parse the 
information about the execution time for each seed from the log.
For legacy reason, the actual weight values are first combined using "combine\_time\_size.sh" and then
formatted correctly to the format expected by MoonLight by using "get\_moonlight\_weight.sh".

get\_size.sh <program>
check\_timeout.sh <program> <initial corpus>
combine\_time\_size.sh <prefix to the output of get\_size.sh and check\_timeout.sh>
get\_moonlight\_weight.sh <program> <infix to the output of get\_size.sh and check\_timeout.sh>
moonlight\_call.sh <program> [ "size" | "time" | "" ]




###################################################################################################
#                                     Configuration Files                                         #
###################################################################################################

The configuration files, files with suffix "\_env" in env subfolder, contains the parameters which
will be used during throughout the experiments. Mainly they specify the arguments to the binary,
memory limit, timeout, and the location of extra libraries needed. 

###################################################################################################
#                                           Fuzzing                                               #
###################################################################################################

These scripts are used as a trivial fuzzing experiment manager. fuzz.sh is the script which will
load configuration file and run a fuzzing experiment accordingly. run.sh invokes a number fuzz.sh 
(limit permitting), and pause when the maximum number of concurrent fuzzing experiment is hit.

###################################################################################################
#                                             Plot                                                #
###################################################################################################

The scripts are used to aggregate the data from several fuzzers in an experiment, calculate the 
average, area under curve, truncating data points to speed up plotting process, and plot figures.
There are two scripts that bind these processes together: get\_plot\_stats.sh to plot coverage and
raw crashes, and generate\_dedup\_plot\_data.sh which plot stack-hash-deduplicated crashes.

get\_plot\_stats.sh <program> <max experiments> <time limit>
generate\_dedup\_plot\_data <program> <time limit>

The time limit is used to cap the time of an experiment in the granularity of hours. The scripts 
expect a directory of fuzzing experiments (and stack\_hashes subdirectory containing stack-hash of a 
corresponding crash) in the format of <program>\_<time\ limit>h, e.g., sox\_18h

Individually, the scripts are the following:
* generate\_plot\_data.py : combine raw data from fuzzing experiments and produce average crashes.
                          The script also produce the maximum map_size / coverage.
* deduplicate.py        : combine stack-hash-deduplicated crashes from fuzzing experiments.
* dedup\_average.py      : produce the average deduplicated crashes (output from deduplicate.py)
* calculate\_AUC.R       : produce the area under curve for the input data, either it is output from
                          generate_plot_data.py or dedup_average.py
* get\_display\_data.R    : truncate the data points that are not visible in the plot to reduce 
                          plot processing time. Takes input from the output of
                          generate_plot_data.py or dedup_average.py
* plot.R                : Main plotting script. Takes input data from the ouput of calculate\_AUC.R
                          and get_display_data.R.
* plot\_utils.R          : Some useful functions used in plot.R, mainly to split the plotting script
                          file so that it is not too big.
