# JLC2024NSP

Installation instructions for different Operating Systems building from sources or using Anaconda for Clingo v5.6.2 can be found here:
https://github.com/potassco/clingo/blob/master/INSTALL.md, https://potassco.org/clingo/,  https://github.com/potassco/clingo/releases/tag/v5.6.2

There are 2 main folders, one for the Encodings and one containing the Input instances.

Inside the Encoding folder, there are 3 files: one is the Direct encoding, the other two represent the encodings for the LBBD methodology, the encoding for the Main problem (MP) and the encoding for the Sub problem (SP).


The Direct encoding can be executed with the following command: 

```./clingo Encoding/Direct.lp input/input_N.lp --restart-on-model --time-limit=120```

For the encodings for the LBBD methodology we suggest using the same command plus the --outf=3 option, to avoid too many outputs in the command line: 

i.e. ```./clingo Encoding/MP.lp input/input_N.lp --restart-on-model --outf=3 --time-limit=120```


 

