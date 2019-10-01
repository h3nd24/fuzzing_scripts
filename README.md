The scripts contained in this archive are used during the experiments, corpus preparation, triage, and 
plotting figures from experiment data.

#                                      Corpus Preparation                                         #

There are various script that are involved with the corpus preparation.
The following two scripts are to ease the calling to manually calling afl-cmin or afl-showmap and 
passing individual parameter set. 
This is to be used in conjunction with the configuration files containing the environment parameters.
There are some sample configuration files in "sample\_env" 
Currently, the location of the configuration files is expected to be in the folder of ~/llvm\_asan/

To obtain the cmin corpus and afl tuples for further processing, execute the following:

```
cmin.sh <initial corpus> <program>
showmaps.sh <initial corpus> <program>
```

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

```
get\_size.sh <program>
check\_timeout.sh <program> <initial corpus>
combine\_time\_size.sh <prefix to the output of get\_size.sh and check\_timeout.sh>
get\_moonlight\_weight.sh <program> <infix to the output of get\_size.sh and check\_timeout.sh>
moonlight\_call.sh <program> [ "size" | "time" | "" ]
```

To produce coverage for minset, we reuse the bitvectors produced by MoonBeam, and create the archive
with necessary information with "minset\_coverage.sh".

```
minset\_coverage.sh <program> <bitvectors> <output directory>
```

There are other scripts that are not directly used to produce the corpora in the MoonLight paper.
check\_weight.sh is used to extract information about the weight in the MoonLight solution.
sort\_coverage.sh and copy\_sorted\_corpus is used to get the (reverse) sorted corpora based on coverage.

```
check\_weight.sh <solution file> <time weight> <file size weight>, the weights are the result of
  get\_moonlight\_weight.sh
sort\_coverage.sh <corpus directory>
copy\_sorted\_corpus.sh <source directory> <target directory> <result of sort\_coverage.sh>
```

In summary, the procedure on getting the corpora in the MoonLight paper:
* Full          : none
* CMIN          : cmin.sh <Full>
* Minset        : showmaps.sh <Full> -> MoonBeam -> minset\_coverage.sh -> minset -> copy the files from Full
* ML-U          : showmaps.sh <Full> -> MoonBeam -> MoonLight -> move\_solution.py -> moonlight\_call.sh
* ML-S and ML-T : showmaps.sh <Full> -> MoonBeam -> check\_timeout.sh -> get\_size.sh -> 
                  combine\_time\_size.sh -> get\_moonlight\_weight.sh -> moonlight\_call.sh
* Random        : create\_random.sh <Full>

If you want to get the (reverse) sorted based on coverage, use sort\_coverage.sh -> copy\_sorted\_corpus.sh
from the AFL tuples of the seeds in the above corpora.

There are scripts to hardlink the original corpora and append empty seed into the corpus.
We have not used this in the paper yet, but this is a work in progress for adding empty seed to other
corpus to see if we have performance benefit.
"add\_empty\_wrapper.sh" is the wrapper to the "add\_empty\_to\_corpus.sh"

```
add\_empty\_wrapper.sh <program> <file extension>
add\_empty\_to\_corpus.sh <original empty corpus> <original source corpus> <output directory> <file extension>
```

#                                     Configuration Files                                         #

The configuration files, files with suffix "\_env" in env subfolder, contains the parameters which
will be used during throughout the experiments. Mainly they specify the arguments to the binary,
memory limit, timeout, and the location of extra libraries needed. 

#                                           Fuzzing                                               #

These scripts are used as a trivial fuzzing experiment manager. fuzz.sh is the script which will
load configuration file and run a fuzzing experiment accordingly. run.sh invokes a number fuzz.sh 
(limit permitting), and pause when the maximum number of concurrent fuzzing experiment is hit.

```
run.sh <priority> <distillation techniques> <program> <starting trial number>
fuzz.sh <program> <distillation technique> <trial number> <fuzzer number>
```

The other scripts are used for archiving, cleaning the queue, and check if the fuzzers are instantiated.
Cleaning the queue is achieved by replacing the files in the queue with empty files.
Checking the how many fuzzers are instantiated is achieved by counting how many "fuzzer\_stats" exist
in the fuzzing output directory.

```
archive.sh <program> <distillation techniques> <minimum trial number> <maximum trial number>
clean\_queue.sh <distillation technique> <trial number>
check\_fuzzers\_sound.sh <distillation techniques> <minimum trial number> <maximum trial number>
```

#                                            Triage                                               #

The scripts for triaging specific targets are contained in their respective subdirectories.
There are three broad vein on how to triage the crashes found in the fuzzing experiment for MoonLight.
* Get the patch for a binary and then check if it does not produce the crash anymore, e.g., FreeType and libxml.
* If the bug is specific enough, then we can use the output of ASAN to distinguish bugs, e.g., SoX on both MP3 and WAV.
* Using breakpoint on GDB to tell if a specific situation which will lead to bug is triggered, mainly on libtiff.

Most of the scripts uses the configuration files and get\_core.sh, and the triage scripts are invoked in the same way.
"get\_core.sh" is a script that is invoked by the triagin script when testing whether a particular 
crash is triggered. 

```
get\_core.sh <program> <experiment directory> <fuzzer number> <crash id>
<program>\_triage.sh <distillation techniques> <minimum trial> <maximum trial> > <program>\_triage\_result
```

Since libtiff is using GDB, there are additional GDB scripts accompanying the script to triage libtiff.

#                                             Plot                                                #

We have a lot of scripts for various plotting purposes, and we tried to label them using tags in the
header of each script.
Some scripts are used to aggregate the data from several fuzzers in an experiment, calculate the 
average, truncating data points to speed up plotting process, and plot figures.
There are two scripts that bind these processes together: get\_get\_coverage.plot.sh to plot coverage, 
and generate\_bug\_plot\_data.sh which plot bugs found overtime.

```
get\_coverage\_plot.sh <program> <time limit>
generate\_bug\_plot\_data.sh <program> <time limit>
```

The time limit is used to cap the time of an experiment in the granularity of hours. The scripts 
expect a directory of fuzzing experiments (and "triage\_output" subdirectory containing the bug class 
of a corresponding crash) in the format of <program>\_<time\ limit>h, e.g., sox\_18h.

We also have script that plots the speedup plot in the paper, and also the distribution of the corpora
in the 2D-space (projected using PCA), and plotting the number of executions allocated for each seed
in the corpus (derivatives from a seed are counted as part of the seed). 
The speedup plot uses the by-product information produced by the scripts to plot bugs overtime as input.

```
plot\_bug\_stats\_aux.sh <program> <output>
Rscript plot\_corpus\_distance.R --algnames <distillation techniques> --inputprefix <prefix to the input files>
  --output <output> --title <plot header>
```

There is no wrapper script for plotting number of executions allocated for each seed.
"plot\_seed\_stats\_grouped.R" is the individual version of the "plot\_seed\_stats.R".

```
Rscript plot\_seed\_stats\_grouped.R --input <input file> --outputprefix <prefix of the output file>
  --title <plot header> --highlight <file containing seed to highlight> --limit <limit on the number of seeds to show> 
```

With respect to the previous plotting functionalities, these are the related scripts:
* generate\_plot\_data.py  : combine the coverage of 8 fuzzers from each fuzzing experiment, and also 
                             produce its average overtime over all of the experiments.
* time\_to\_find.py        : combine triaged bugs from fuzzing experiments.
* dedup\_average.py        : produce the average bugs over time (output of time\_to\_find.py)
* calculate\_AUC.R         : produce the area under curve for the input data, either it is output from
                             generate_plot_data.py or dedup_average.py
* get\_display\_data.R     : truncate the data points that are not visible in the plot to reduce 
                             plot processing time. Takes input from the output of
                             generate_plot_data.py or dedup_average.py
* plot.R                   : Main plotting script. Takes input data from the ouput of calculate\_AUC.R
                             and get_display_data.R.
* plot\_utils.R            : Some useful functions used in plot.R, mainly to split the plotting script
                             file so that it is not too big and modularity / reusability.
* pca.py                   : Get the 2D PCA operators from the tuples in a corpus directory (Full).
* pca\_transform.py        : Project the tuples in a corpus directory according to the operators learned by pca.py
* plot\_legend.R           : Plot the legend for bug / coverage over time as separate file for modularity 
                             in the Latex file.
* csv\_to\_file.py         : This script is used to setup the fuzzing directories with the bugs from
                             triage result. This is because time\_to\_find.py expect the directory structure
                             and crash IDs to be the same as the fuzzing experiment.
* fill\_non\_bugs.sh       : This script pad the triage result with no bug ("") when a particular crash is 
                             not a bug. This is because sometimes people give me triage result of only
                             interesting bugs and leave behind the non-bug crashes.
* count\_execs.py          : Trace the AFL queue back to their sources and gather the statistics, i.e., 
                             the number of executions allocated to this seed.
* count\_execs\_avg.py     : Aggregate the result of "count\_execs.py" in the form of mean and standard deviation.

Apart from the previously mentioned scripts, there are various auxilliary scripts:
* calculate\_CV.py         : Script to get the coefficient of variation on the experiments result. This is
                             deprecated since we removed the tables from the paper.
* compare\_result.sh       : Simple script to help me eyeball the output of "calculate\_AUC.R"
* convert\_pdf\_to\_jpg.sh : Rasterize a vector image (PDF), mainly used for plotting the corpus distance.
                             We would love to maintain the vector format, but then it will take forever to
                             display due to the number of data points from full corpus, c'est la vie.
* get\_bug\_count.sh       : Get the number of trials in the campaign (of a distillation) that hit a particular bug.
* get\_CV\_table.sh        : The wrapper script to call "calculate\_CV.py" and format it into the Latex format.
* get\_vda\_from\_log.sh   : Get the VD.A values from the log of executing "plot.R" with "--conclusion" enabled.
* produce\_vda\_table.sh   : Format the output of "get\_vda\_from\_log.sh" into Latex format.
* trace\_source\_main.sh   : Wraps the other trace source scripts, used to get an idea of which seed produce
                             which bugs.
* trace\_source.py         : Predecessor of "count\_execs.py", mainly this is tracing a crash to its source(s).
* trace\_source\_setup.sh  : Setup the fuzzing experiments to have crash directories which contains only
                             a particular bug. 
